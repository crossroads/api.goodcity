module ValidateTwilioRequest

  extend ActiveSupport::Concern

  private

  def validate_twilio_request
    unless validator.validate(request.url, post_vars, signature)
      raise(TwilioAuthenticationError, "Invalid Request!")
    end
  end

  def validator
    Twilio::Util::RequestValidator.new twilio_token
  end

  def post_vars
    params.except("action", "controller", "format")
  end

  def signature
    request.headers["X-Twilio-Signature"]
  end

  def twilio_token
    Rails.application.secrets.twilio["auth_token"]
  end

  class TwilioAuthenticationError < StandardError; end
end
