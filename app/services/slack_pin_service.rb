class SlackPinService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def send_otp
    channel = ENV['SLACK_PIN_CHANNEL']
    token = @user.most_recent_token
    message = "[#{Rails.env}] " + I18n.t('twilio.sms_verification_pin', pin: token.otp_code)
    SlackMessageJob.perform_later(message, channel)
  end

end
