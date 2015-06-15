require "twilio-ruby"

module Api::V1
  class TwilioController < Api::V1::ApiController
    include Webhookable

    after_filter :set_header
    skip_authorization_check
    skip_before_action :validate_token
    skip_before_action :verify_authenticity_token

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
          # ask Donor to leave message on voicemail
          r.Gather numDigits: "1", action: "/api/v1/accept_voicemail", method: "get" do |g|
            g.Say "Press 1 to leave a message after the tone and our staff will get back to you as soon as possible. Thank you"
            g.Say "Or Press any other key to finish the call."
          end
        end
      end

      render_twiml response
    end

    def accept_voicemail
      if params["Digits"] == "1"
        response = Twilio::TwiML::Response.new do |r|
          r.Record maxLength: "60", playBeep: true, action: "/api/v1/send_voicemail", method: "get"
        end
      end
      render_twiml response
    end

    def send_voicemail
      user = User.user_exist?(params["From"]) if params["From"]
      SendVoicemailJob.perform_later(params["RecordingUrl"], user.try(:id))
      response = Twilio::TwiML::Response.new do |r|
        r.Say "Goodbye."
      end
      render_twiml response
    end
  end
end
