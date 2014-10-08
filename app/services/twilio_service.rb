require 'twilio-ruby'
class TwilioService

  attr_accessor :user

  def initialize(user)
    @user = user
  end

  def sms_verification_pin(options = {})
    begin
      body = I18n.t('twilio.sms_verification_pin', pin: options[:otp], expiry: options[:otp_expires])
      twilio_client.account.sms.messages.create({
        from: twilio_conf['phone_number'],
        to: @user.mobile,
        body: body})
    rescue Twilio::REST::RequestError => e
       raise
    end
  end

  private

  def twilio_client
    @twilio_client ||= begin
        Twilio::REST::Client.new(twilio_conf['account_sid'], twilio_conf['auth_token'])
      rescue Twilio::REST::RequestError => e
       raise
      end
  end

  def twilio_conf
    Rails.application.secrets.twilio
  end

end
