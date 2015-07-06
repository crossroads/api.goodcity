require "twilio-ruby"

module Api::V1
  class TwilioOutboundController < Api::V1::ApiController
    include TwilioConfig

    after_filter :set_header, except: :generate_call_token

    resource_description do
      short "Handle Twilio Outbound Calls"
      description <<-EOS
        - Admin staff can call to Donor via Twilio.
        - If Donor is busy, not-answering or call-fails then it will play
          message to Admin.
        - After call completion it will add call-log message to Offer's Private Messaging thread.
      EOS
      formats ['application/json', 'text/xml']
      error 404, "Not Found"
      error 500, "Internal Server Error"
    end

    api :POST, '/v1/twilio_outbound/connect_call', "When Admin make a call \
    to Donor from application using Twilio Twiml app, it will request for the\
    response to be sent over it."
    param :AccountSid, String, desc: "Twilio Account SID"
    param :ApplicationSid, String, desc: "Twilio Twiml Application SID"
    param :Caller, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
    param :CallStatus, String, desc: "Status of Call ex: 'ringing'"
    param :phone_number, String, desc: "Number to which call should be made. Here we are passing Combination of '<current_user_id>#<offer_id>#<phone_number>'"
    param :CallSid, String, desc: "SID of current call"
    param :From, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
    param :Direction, String, desc: "Inbound or Outbound"
    param :ApiVersion, String, desc: "Twilio API version"
    def connect_call
      caller_id, offer_id, mobile = params["phone_number"].split("#")
      # mobile = "+919172034260"
      redis.hmset("twilio_outbound_#{mobile}",
        :offer_id, offer_id,
        :caller_id, caller_id)

      response = Twilio::TwiML::Response.new do |r|
        r.Dial callerId: voice_number, action: api_v1_twilio_outbound_completed_call_path do |d|
          d.Number mobile
        end
      end
      render_twiml response
    end

    api :POST, '/v1/twilio_outbound/completed_call', "Outbound call from Admin to donor: Response sent to twilio when call fails, timeout or no response from Donor."
    param :AccountSid, String, desc: "Twilio Account SID"
    param :ApplicationSid, String, desc: "Twilio Twiml Application SID"
    param :CallStatus, String, desc: "Status of Call initialted by Admin (parent call)ex: 'in-progress'"
    param :DialCallSid, String, desc: "SID of call between admin-donor"
    param :DialCallStatus, String, desc: "Status of Call between admin-donor (child call)ex: 'completed'"
    param :Direction, String, desc: "Inbound or Outbound"
    param :ApiVersion, String, desc: "Twilio API version"
    param :Caller, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
    param :CallSid, String, desc: "SID of call initialted by Admin"
    param :DialCallDuration, String, desc: "Admin-donor call duration in seconds (child-call)"
    param :From, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
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
    param :AccountSid, String, desc: "Twilio Account SID"
    param :ApplicationSid, String, desc: "Twilio Twiml Application SID"
    param :Caller, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
    param :CallStatus, String, desc: "Status of Call ex: 'completed'"
    param :CallSid, String, desc: "SID of current call"
    param :From, String, desc: "Name of the caller or phone number ex: 'client:Anonymous'"
    param :Direction, String, desc: "Inbound or Outbound"
    param :ApiVersion, String, desc: "Twilio API version"
    param :Duration, String
    param :CallDuration, String, desc: "Call duration in seconds"
    param :Timestamp, String
    param :CallbackSource, String
    param :SequenceNumber, String
    def call_status
      offer_id = redis.hmget("twilio_outbound_#{child_call.to}", :offer_id)
      user_id  = redis.hmget("twilio_outbound_#{child_call.to}", :caller_id)
      redis.del("twilio_outbound_#{child_call.to}")
      SendOutboundCallStatusJob.perform_later(user_id, offer_id, child_call.status)
      render json: {}
    end

    api :GET, '/v1/twilio_outbound/generate_call_token', "Generate Twilio Ougoing Call Capability Token."
    def generate_call_token
      render json: { token: twilio_outgoing_call_capability.generate }
    end
  end
end
