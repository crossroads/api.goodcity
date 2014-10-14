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
    options = { from: twilio_conf['phone_number'], to: @user.mobile, body: body}
    twilio_client.account.sms.messages.create(options)
  end

  private

  def twilio_client
    @twilio_client ||= begin
      Twilio::REST::Client.new(twilio_conf['account_sid'], twilio_conf['auth_token'])
    end
  end

  def twilio_conf
    Rails.application.secrets.twilio
  end

  def allowed_to_send?
    mobile = @user.mobile
    ENV['VALID_SMS_NUMBERS'].split(",").map(&:strip).include?(mobile)
  end

end
