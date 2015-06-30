require "twilio-ruby"
require "goodcity/redis"

module Api::V1
  class TwilioController < Api::V1::ApiController
    include Webhookable

    after_filter :set_header, except: [:assignment, :hold_music]
    skip_authorization_check
    skip_before_action :validate_token
    skip_before_action :verify_authenticity_token

    def assignment
      set_json_header
      donor_id = JSON.parse(params["TaskAttributes"])["user_id"]
      mobile   = redis.get("twilio_donor_#{donor_id}")

      if mobile
        assignment_instruction = {
          instruction: 'dequeue',
          post_work_activity_sid: activity_sid("Offline"),
          from: TWILIO_VOICE_NUMBER,
          to: mobile
        }
      else
        assignment_instruction = {}
      end
      render json: assignment_instruction.to_json
    end

    # This action will be called from twilio when call is completed
    def call_summary
      delete_redis_keys(user.id)
      mark_worker_offline
      render json: {}
    end

    # This action will be called from twilio when runtime exception
    # Example Parameters received from Twilio are
    # {"AccountSid"=>"..", "ToZip"=>"", "FromState"=>"", "Called"=>"+85258087803", "FromCountry"=>"LS", "CallerCountry"=>"LS", "CalledZip"=>"", "ErrorUrl"=>"http://6b6d4611.ngrok.io/api/v1/twilio/voice", "Direction"=>"inbound", "FromCity"=>"", "CalledCountry"=>"HK", "CallerState"=>"", "CallSid"=>"..", "CalledState"=>"", "From"=>"+266696687", "CallerZip"=>"", "FromZip"=>"", "CallStatus"=>"ringing", "ToCity"=>"", "ToState"=>"", "To"=>"+85258087803", "ToCountry"=>"HK", "CallerCity"=>"", "ApiVersion"=>"2010-04-01", "Caller"=>"+266696687", "CalledCity"=>"", "ErrorCode"=>"11200"}
    def call_fallback
      Airbrake.notify(Exception, parameters: params,
        error_class: "TwilioError", error_message: "Twilio Voice Call Error")
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Unfortunately there is some issue with connecting to Goodcity. Please try again after some time. Thank you."
        r.Hangup
      end
      render_twiml response
    end

    def voice
      inactive_caller, user = User.inactive?(params["From"]) if params["From"]

      response = Twilio::TwiML::Response.new do |r|
        if(inactive_caller)
          r.Dial { |d| d.Number GOODCITY_NUMBER }
        else
          task = { "selected_language" => "en", "user_id" => user.id }.to_json
          r.Enqueue workflowSid: twilio_creds["workflow_sid"], waitUrl: "/api/v1/hold_gc_donor", waitUrlMethod: "post" do |t|
            t.TaskAttributes task
          end

          ask_callback(r)
          accept_voicemail(r)
        end
      end
      render_twiml response
    end

    def hold_gc_donor
      notify_reviewer

      if(params['QueueTime'].to_i < TWILIO_QUEUE_WAIT_TIME)
        response = Twilio::TwiML::Response.new do |r|
          r.Say "Hello #{user.full_name}," if user
          r.Say THANK_YOU_CALLING_MESSAGE
          r.Play api_v1_twilio_hold_music_url
        end
      else
        response = Twilio::TwiML::Response.new { |r| r.Leave }
      end
      render_twiml response
    end

    def ask_callback(r)
      # ask Donor to leave message on voicemail
      r.Gather numDigits: "1", timeout: 3,  action: "/api/v1/accept_callback", method: "get" do |g|
        g.Say "Unfortunately it none of our staff are able to take your call at the moment."
        g.Say "You can request a call-back without leaving a message by pressing 1."
        g.Say "Otherwise, leave a message after the tone and our staff will get back to you as soon as possible. Thank you."
      end
    end

    def accept_callback
      if params["Digits"] == "1"
        SendDonorCallResponseJob.perform_later(user.try(:id))
        response = Twilio::TwiML::Response.new do |r|
          r.Say "Thank you, our staff will call you as soon as possible. Goodbye."
          r.Hangup
        end
      end
      render_twiml response
    end

    def accept_voicemail(r)
      r.Record maxLength: "60", playBeep: true, action: "/api/v1/send_voicemail", method: "get"
    end

    def send_voicemail
      SendDonorCallResponseJob.perform_later(user.try(:id), params["RecordingUrl"])
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Goodbye."
        r.Hangup
      end
      render_twiml response
    end

    def accept_call
      unless redis.get("twilio_donor_#{params['donor_id']}")
        redis_storage("twilio_donor_#{params['donor_id']}", params['mobile'])
        offline_worker.update(activity_sid: activity_sid('Idle'))
        AcceptedCallNotificationJob.perform_later(params['donor_id'], params['mobile'])
      end
      render json: {}
    end

    def hold_music
      response.headers["Content-Type"] = "audio/mpeg"
      send_file "app/assets/audio/30_sec_hold_music.mp3", type: "audio/mpeg"
    end

    private

    def activity_sid(friendly_name)
      task_router.activities.list(friendly_name: friendly_name).first.sid
    end

    def delete_redis_keys(user_id)
      redis.del("twilio_donor_#{user_id}")
      redis.del("twilio_notify_#{user_id}")
    end

    def idle_worker
      task_router.workers.list(activity_name: "Idle").first
    end

    def mark_worker_offline
      idle_worker && idle_worker.update(activity_sid: activity_sid('Offline'))
    end

    def notify_reviewer
      # notify only once when at least one worker is offline
      if offline_worker && redis.get("twilio_notify_#{user.id}").blank?
        SendDonorCallingNotificationJob.perform_later(user.id)
        redis_storage("twilio_notify_#{user.id}", true)
      end
    end

    def offline_worker
      task_router.workers.list(activity_name: "Offline").first
    end

    def task_router
      @client = Twilio::REST::TaskRouterClient.new(twilio_creds["account_sid"],
        twilio_creds["auth_token"], twilio_creds["workspace_sid"])
    end

    def twilio_creds
      @twilio ||= Rails.application.secrets.twilio
    end

    def redis_storage(key, value)
      redis.set(key, value)
      redis.expireat(key, Time.now.to_i + 60)
    end

    def redis
      @redis ||= Goodcity::Redis.new
    end

    def user
      @user ||= User.user_exist?(params["From"])
    end
  end
end
