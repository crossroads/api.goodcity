require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin
    return unless allowed_to_send?
    token = user.most_recent_token
    code = token.otp_code
    expiry = token.otp_code_expiry.strftime("%A %b %e %H:%M")
    body = I18n.t('twilio.sms_verification_pin', pin: code, expiry: expiry)
    options = { to: @user.mobile, body: body}
    TwilioJob.perform_later(options)
  end

  private

  def allowed_to_send?
    mobile = @user.mobile
    ENV['VALID_SMS_NUMBERS'].split(",").map(&:strip).include?(mobile)
  end

end
