require "twilio-ruby"

module Api::V1
  class TwilioController < Api::V1::ApiController
    include Webhookable

    after_filter :set_header, except: :assignment
    skip_authorization_check
    skip_before_action :validate_token
    skip_before_action :verify_authenticity_token

    def assignment
      set_json_header
      donor_id = JSON.parse(params["TaskAttributes"])["user_id"]
      mobile   = $redis.get("twilio_donor_#{donor_id}")

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
      delete_redis_keys(donor_id)
      render json: assignment_instruction.to_json
    end

    def voice
      inactive_caller, user = User.inactive?(params["From"]) if params["From"]

      response = Twilio::TwiML::Response.new do |r|
        r.Say "Hello #{user.full_name}," if user
        r.Say THANK_YOU_CALLING_MESSAGE

        if(inactive_caller)
          r.Dial do |d|
            d.Number GOODCITY_NUMBER
          end
        else
          task = { "selected_language" => "en", "user_id" => user.id }.to_json
          r.Enqueue workflowSid: twilio_creds["workflow_sid"], waitUrl: "/api/v1/hold_gc_donor", waitUrlMethod: "post" do |t|
            t.TaskAttributes task
          end

          ask_voicemail(r)
        end
      end
      render_twiml response
    end

    def hold_gc_donor
      notify_reviewer

      if(params['QueueTime'].to_i < 45)
        response = Twilio::TwiML::Response.new do |r|
          r.Say "Kindly wait for few seconds"
          r.Say THANK_YOU_CALLING_MESSAGE
        end
        render_twiml response
      else
        response = Twilio::TwiML::Response.new { |r| r.Leave }
        render_twiml response
      end
    end

    def ask_voicemail(r)
      idle_worker && idle_worker.update(activity_sid: activity_sid('Offline'))

      # ask Donor to leave message on voicemail
      r.Gather numDigits: "1", action: "/api/v1/accept_voicemail", method: "get" do |g|
        g.Say "Unfortunately it none of our staff are able to take your call at the moment."
        g.Say "Press 1 to leave a message after the tone and our staff will get back to you as soon as possible. Thank you."
        g.Say "Or Press any other key to finish the call."
      end
    end

    def accept_voicemail
      if params["Digits"] == "1"
        response = Twilio::TwiML::Response.new do |r|
          r.Record maxLength: "60", playBeep: true, action: "/api/v1/send_voicemail", method: "get"
        end
      else
        response = Twilio::TwiML::Response.new { |r| r.Hangup }
      end
      render_twiml response
    end

    def send_voicemail
      user = User.user_exist?(params["From"]) if params["From"]
      SendVoicemailJob.perform_later(params["RecordingUrl"], user.try(:id))
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Goodbye."
        r.Hangup
      end
      delete_redis_keys(user.id)
      render_twiml response
    end

    def accept_call
      redis_storage("twilio_donor_#{params['donor_id']}", params['mobile'])
      offline_worker.update(activity_sid: activity_sid('Idle'))
      render json: {}
    end

    private

    def activity_sid(friendly_name)
      task_router.activities.list(friendly_name: friendly_name).first.sid
    end

    def delete_redis_keys(user_id)
      $redis.del("twilio_donor_#{user_id}")
      $redis.del("twilio_notify_#{user_id}")
    end

    def notify_reviewer
      # notify only once when at least one worker is offline
      if offline_worker && $redis.get("twilio_notify_#{user.id}").blank?
        SendDonorCallingNotificationJob.perform_later(user.id)
        redis_storage("twilio_notify_#{user.id}", true)
      end
    end

    def offline_worker
      task_router.workers.list(activity_name: "Offline").first
    end

    def idle_worker
      task_router.workers.list(activity_name: "Idle").first
    end

    def task_router
      @client = Twilio::REST::TaskRouterClient.new(twilio_creds["account_sid"],
        twilio_creds["auth_token"], twilio_creds["workspace_sid"])
    end

    def twilio_creds
      @twilio ||= Rails.application.secrets.twilio
    end

    def user
      @user ||= User.user_exist?(params["From"])
    end

    def redis_storage(key, value)
      $redis.set(key, value)
      $redis.expireat(key, Time.now.to_i + 60)
    end

  end
end
