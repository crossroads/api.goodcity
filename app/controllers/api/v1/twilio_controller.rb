require "twilio-ruby"

module Api::V1
  class TwilioController < Api::V1::ApiController
    include TwilioConfig

    after_filter :set_header, except: [:assignment, :hold_music]

    resource_description do
      short "Handle Twilio Inbound Voice Calls"
      description <<-EOS
        - Call from Donor is notified to Goodcity Staff who is subscribed
          to the Donor's recent Offer's private message thread.
        - Twilio will redirect it to the person who accepts the call.
          (Implemented using Twilio's Taskrouter feature.)
        - In case of any call-fallback, it will send airbreak notice.
      EOS
      formats ['application/json', 'text/xml']
      error 404, "Not Found"
      error 500, "Internal Server Error"
    end

    def_param_group :twilio_params do
      param :CallSid, String, desc: "SID of call"
      param :AccountSid, String, desc: "Twilio Account SID"
      param :ApiVersion, String, desc: "Twilio API version"
      param :Direction, String, desc: "inbound or outbound"
      param :To, String, desc: "phone number dialed by User(Donor)"
      param :Called, String, desc: "phone number dialed by User(Donor)"
      param :Caller, String, desc: "Phone number of Caller(Donor)"
      param :From, String, desc: "Phone number of Caller(Donor)"
    end

    api :POST, "/v1/twilio/assignment", "Called by Twilio when worker becomes Idle and Task is added to TaskQueue"
    param :AccountSid, String, desc: "Twilio Account SID"
    param :WorkspaceSid, String, desc: "Twilio Workspace SID"
    param :WorkflowSid, String, desc: "Twilio Workflow SID"
    param :ReservationSid, String, desc: "Twilio Task Reservation SID"
    param :TaskQueueSid, String, desc: "Twilio Task Queue SID"
    param :TaskSid, String, desc: "Twilio current Task SID"
    param :WorkerSid, String, desc: "Twilio worker SID"
    param :TaskAge, String
    param :TaskPriority, String
    param :TaskAttributes, String, desc: <<-EOS
      Serialized hash of following Task Attributes
      - param :caller, String, desc: 'Phone number of Caller(Donor)'
      - param :To, String, desc: 'phone number dialed by User(Donor)'
      - param :Called, String, desc: 'phone number dialed by User(Donor)'
      - param :direction, String, desc: 'inbound or outbound'
      - param :from, String, desc: 'Phone number of Caller(Donor)'
      - param :api_version, String, desc: 'Twilio API version'
      - param :call_sid, String, desc: 'SID of call'
      - param :user_id, Integer, desc: 'id of user(donor)'
      - param :selected_language, String, desc: 'ex: 'en''
      - param :call_status, String, desc: 'Status of call ex: ringing'
      - param :account_sid, String, desc: 'Twilio Account SID'
    EOS
    param :WorkerAttributes, String, desc: <<-EOS
      Serialized hash of following Worker Attributes
      - param :languages, Array, desc: "ex: [\"en\"]"
      - param :user_id, String, desc: "Id of User"
    EOS
    def assignment
      set_json_header
      donor_id = JSON.parse(params["TaskAttributes"])["user_id"]
      mobile   = redis.get("twilio_donor_#{donor_id}")

      if mobile
        assignment_instruction = {
          instruction: 'dequeue',
          post_work_activity_sid: activity_sid("Offline"),
          from: voice_number,
          to: mobile
        }
      else
        assignment_instruction = {}
      end
      render json: assignment_instruction.to_json
    end

    api :POST, '/v1/twilio/call_summary', "This action will be called from twilio when call is completed"
    description <<-EOS
      - Delete details related to current call from Redis
      - Update twilio-worker state from 'Idle' to 'Offline'
    EOS
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of call ex: completed"
    param :Timestamp, String, desc: "Timestamp when call is completed"
    param :CallDuration, String, desc: "Time Duration of Call in seconds"
    def call_summary
      delete_redis_keys(user.id)
      mark_worker_offline
      render json: {}
    end

    api :POST, '/v1/twilio/call_fallback', "On runtime exception, invalid response or timeout at api request from Twilio to our application(at 'api/v1/twilio/voice')"
    param_group :twilio_params
    param :ErrorUrl, String, desc: "Url at which error is occured ex: 'http://api-staging.goodcity.hk/api/v1/twilio/voice'"
    param :CallStatus, String, desc: "Status of call ex: ringing"
    param :ErrorCode, String, desc: "Code of error, ex: 11200"
    def call_fallback
      Airbrake.notify(Exception, parameters: params,
        error_class: "TwilioError", error_message: "Twilio Voice Call Error")
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Unfortunately there is some issue with connecting to Goodcity. Please try again after some time. Thank you."
        r.Hangup
      end
      render_twiml response
    end

    api :POST, "/v1/twilio/voice", "Called by Twilio when Donor calls to Goodcity Voice Number."
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of call ex: ringing"
    def voice
      inactive_caller, user = User.inactive?(params["From"]) if params["From"]

      response = Twilio::TwiML::Response.new do |r|
        if(inactive_caller)
          r.Dial { |d| d.Number GOODCITY_NUMBER }
        else
          task = { "selected_language" => "en", "user_id" => user.id }.to_json
          r.Enqueue workflowSid: twilio_creds["workflow_sid"], waitUrl: api_v1_hold_gc_donor_path, waitUrlMethod: "post" do |t|
            t.TaskAttributes task
          end

          ask_callback(r)
          accept_voicemail(r)
        end
      end
      render_twiml response
    end

    api :POST, '/v1/hold_gc_donor', "Twilio Response to the caller waiting in queue"
    param_group :twilio_params
    param :QueueSid, String, desc: "Twilio API version"
    param :CallStatus, String, desc: "Status of call ex: ringing"
    param :QueueTime, String, desc: "Time spent by current caller in queue"
    param :AvgQueueTime, String
    param :QueuePosition, String
    param :CurrentQueueSize, String
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
      r.Gather numDigits: "1", timeout: 3,  action: api_v1_accept_callback_path do |g|
        g.Say "Unfortunately none of our staff are able to take your call at the moment."
        g.Say "You can request a call-back without leaving a message by pressing 1."
        g.Say "Otherwise, leave a message after the tone and our staff will get back to you as soon as possible. Thank you."
      end
    end

    api :POST, "/v1/accept_callback", "Twilio response sent when user press 1 key"
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of call ex: in-progress"
    param :Digits, String, desc: "Digits entered by Caller"
    param :msg, String
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
      r.Record maxLength: "60", playBeep: true, action: api_v1_send_voicemail_path
    end

    api :POST, '/v1/send_voicemail', "After voicemail, recording-Link sent to message thread and call is disconnected."
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of call ex: completed"
    param :RecordingUrl, String, desc: "Url of recording ex: http://api.twilio.com/2010-04-0Accounts/account_sid/Recordings/recording_sid"
    param :Digits, String
    param :RecordingDuration, String, desc: "Recording Duration in seconds"
    param :RecordingSid, String, desc: "SID of recording"
    def send_voicemail
      SendDonorCallResponseJob.perform_later(user.try(:id), params["RecordingUrl"])
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Goodbye."
        r.Hangup
      end
      render_twiml response
    end

    api :GET, '/v1/twilio/accept_call'
    description <<-EOS
      - Set redis value: { "twilio_donor_<donor_id>" => <mobile> }
      - Update twilio-worker state from 'Offline' to 'Idle'
      - Send Call notification to Admin Staff.
    EOS
    def accept_call
      donor_id = params['donor_id']

      unless redis.get("twilio_donor_#{donor_id}")
        redis_storage("twilio_donor_#{donor_id}", params['mobile'])
        offline_worker.update(activity_sid: activity_sid('Idle'))

        donor    = User.find(donor_id)
        receiver = User.find_by_mobile(params['mobile'])
        offer    = Offer.find(donor.recent_active_offer_id)

        PushService.new.send_notification offer.call_notify_channels - ["user_#{receiver.id}"], true, {
          category:   'call_answered',
          message:    "Call from #{donor.full_name} has been accepted by #{receiver.full_name}",
          author_id:  donor_id
        }

        Version.create(
          item_type:    'Offer',
          item_id:      offer.id,
          event:        'call_accepted',
          whodunnit:    receiver.id.to_s
        )
      end
      render json: {}
    end

    api :GET, '/v1/twilio/hold_music', "Returns mp3 file played for user while waiting in queue."
    def hold_music
      response.headers["Content-Type"] = "audio/mpeg"
      send_file "app/assets/audio/30_sec_hold_music.mp3", type: "audio/mpeg"
    end

    private

    def delete_redis_keys(user_id)
      redis.del("twilio_donor_#{user_id}")
      redis.del("twilio_notify_#{user_id}")
    end

    def notify_reviewer
      # notify only once when at least one worker is offline
      if offline_worker && redis.get("twilio_notify_#{user.id}").blank?
        offer = Offer.find(user.recent_active_offer_id)

        PushService.new.send_notification offer.call_notify_channels, true, {
          category:   'incoming_call',
          message:    "#{user.full_name} calling now..",
          author_id:  user.id
        }

        Version.create(
          item_type:    'Offer',
          item_id:      offer.id,
          event:        'donor_called',
          whodunnit:    user.id.to_s
        )

        redis_storage("twilio_notify_#{user.id}", true)
      end
    end

    def redis_storage(key, value)
      redis.set(key, value)
      redis.expireat(key, Time.now.to_i + 60)
    end
  end
end
