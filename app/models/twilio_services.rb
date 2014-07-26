require 'twilio-ruby'
class TwilioServices

  TWILIO_CONF = YAML.load(File.read(Rails.root.join('config','twilio.yml')))[Rails.env]
  begin
    TWILIO_CLIENT = Twilio::REST::Client.new(TWILIO_CONF['account_sid'], TWILIO_CONF['auth_token'])
  rescue Twilio::REST::RequestError => e
     raise
  end

  def initialize(user)
    @user = user
  end

  def sms_verification_pin(options = {})
    begin
      body = I18n.t('twilio.sms_verification_pin', pin: options[:otp], expiry: options[:otp_expires])
      TWILIO_CLIENT.account.sms.messages.create({
        from: TWILIO_CONF['twilio_phone_number'],
        to: @user.mobile,
        body: body})
    rescue Twilio::REST::RequestError => e
       raise
    end
  end
end
