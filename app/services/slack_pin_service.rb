class SlackPinService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def send_otp(app_name)
    channel = ENV['SLACK_PIN_CHANNEL']
    token = @user.most_recent_token
    
    message = "[#{Rails.env}] " + message_text(app_name, token)
    SlackMessageJob.perform_later(message, channel)
  end

  private

  def message_text(app_name, token)
    if app_name == BROWSE_APP
      I18n.t('twilio.browse_sms_verification_pin', pin: token.otp_code)
    else
      I18n.t('twilio.sms_verification_pin', pin: token.otp_code)
    end
  end
end
