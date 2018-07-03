class SlackPinService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def send_otp
    SlackMessageJob.perform_later(message)
  end

  private

  def message
    token = @user.most_recent_token
    I18n.t('twilio.sms_verification_pin', pin: token.otp_code)
  end

end
