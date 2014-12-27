require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin
    return unless allowed_to_send?
    pin = user.most_recent_token.otp_code
    body = I18n.t('twilio.sms_verification_pin', pin: pin)
    options = {to: @user.mobile, body: body}
    TwilioJob.perform_later(options)
  end

  private

  def allowed_to_send?
    mobile = @user.mobile
    ENV['VALID_SMS_NUMBERS'].split(",").map(&:strip).include?(mobile)
  end

end
