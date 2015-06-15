require 'twilio-ruby'

module Api::V1
  class TwilioController < Api::V1::ApiController
    include Webhookable

    after_filter :set_header
    skip_authorization_check
    skip_before_action :validate_token
    skip_before_action :verify_authenticity_token

    def voice
      inactive_caller = params["From"] ? User.inactive?(params["From"]) : false
      response = Twilio::TwiML::Response.new do |r|
        r.Say THANK_YOU_CALLING_MESSAGE, voice: 'alice'

        if(inactive_caller)
          r.Dial do |d|
            d.Number GOODCITY_NUMBER
          end
        end
      end

      render_twiml response
    end
  end
end
