require "twilio-ruby"

module Api::V1
  class TwilioOutboundController < Api::V1::ApiController
    include TwilioConfig

    skip_authorization_check
    skip_before_action :validate_token, except: :generate_call_token
    skip_before_action :verify_authenticity_token, except: :generate_call_token
    after_filter :set_header, except: :generate_call_token

    resource_description do
      short "Handle Twilio Outbound Calls"
      description <<-EOS
        - Admin staff can call to Donor via Twilio.
        - If Donor is busy, not-answering or call-fails then it will play
          message to Admin.
        - After call completion it will add call-log message to Offer's Private Messaging thread.
        - {Click for a Tech Diagram}[https://docs.google.com/drawings/d/1vlBcYUqLMv59ggetGAx-SStzF3hF7NxsSLtcduwYjhA/edit]
      EOS
      formats ['application/json', 'text/xml']
      error 404, "Not Found"
      error 500, "Internal Server Error"
    end

    def_param_group :twilio_params do
      param :ApplicationSid, String, desc: "Twilio Twiml Application SID"
      param :CallSid, String, desc: "SID of call initialted by Admin"
      param :AccountSid, String, desc: "Twilio Account SID"
      param :ApiVersion, String, desc: "Twilio API version"
      param :Direction, String, desc: "inbound or outbound"
      param :Caller, String, desc:  "Name of the caller or phone number ex: 'client:Anonymous'"
      param :From, String, desc:  "Name of the caller or phone number ex: 'client:Anonymous'"
    end

    api :POST, '/v1/twilio_outbound/connect_call', "When an Admin calls \
    a donor from the application, Twilio will call this hook to determine what\
    it should do (who to call etc...)"
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of Call ex: 'ringing'"
    param :phone_number, String, desc: "Number to which call should be made. Here we are passing Combination of '<offer_id>#<caller_id>'"
    def connect_call
      offer_id, caller_id = params["phone_number"].split("#")
      mobile = Offer.find_by(id: offer_id).created_by.mobile
      TwilioOutboundCallManager.new(to: mobile, offer_id: offer_id, user_id: caller_id).store

      response = Twilio::TwiML::Response.new do |r|
        r.Dial callerId: voice_number, action: api_v1_twilio_outbound_completed_call_path do |d|
          d.Number mobile
        end
      end
      render_twiml response
    end

    api :POST, '/v1/twilio_outbound/completed_call', "Outbound call from Admin to donor: Response sent to twilio when call fails, timeout or no response from Donor."
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of Call initialted by Admin (parent call)ex: 'in-progress'"
    param :DialCallSid, String, desc: "SID of call between admin-donor"
    param :DialCallStatus, String, desc: "Status of Call between admin-donor (child call)ex: 'completed'"
    param :DialCallDuration, String, desc: "Admin-donor call duration in seconds (child-call)"
    def completed_call
      response = Twilio::TwiML::Response.new do |r|
        unless params["DialCallStatus"] == "completed"
          r.Say "Couldn't reach #{user(child_call.to).full_name} try again soon. Goodbye."
        end
        r.Hangup
      end
      render_twiml response
    end

    api :POST, '/v1/twilio_outbound/call_status', "Called from Twilio when outbound call between Admin and Donor is completed."
    param_group :twilio_params
    param :CallStatus, String, desc: "Status of Call ex: 'completed'"
    param :Duration, String
    param :CallDuration, String, desc: "Call duration in seconds"
    param :Timestamp, String
    param :CallbackSource, String
    param :SequenceNumber, String
    def call_status
      tcm = TwilioOutboundCallManager.new(to: child_call.to)
      SendOutboundCallStatus.new(tcm.user_id, tcm.offer_id, child_call.status).notify
      tcm.remove
      render json: {}
    end

    api :GET, '/v1/twilio_outbound/generate_call_token', "Generate Twilio Outgoing Call Capability Token. This allows clients to authenticate with Twilio and place calls etc."
    def generate_call_token
      render json: { token: twilio_outgoing_call_capability.generate }
    end

  end
end
