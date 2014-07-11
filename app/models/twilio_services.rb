require 'twilio-ruby'
class TwilioServices

  TWILIO_CONF = YAML.load(File.read(Rails.root.join('config','twilio.yml')))[Rails.env]
  begin
    TWILIO_CLIENT = Twilio::REST::Client.new(TWILIO_CONF['account_sid'], TWILIO_CONF['auth_token'])
  rescue Twilio::REST::RequestError => e
    e.message
  end

  def initialize(user)
    @user = user
  end

  def sms_verification_pin(options = {})
    TWILIO_CLIENT.account.sms.messages.create({
        from: TWILIO_CONF['twilio_phone_number'],
        to: @user.mobile,
        body: "Your pin is #{options[:otp]} and this pin will expire by #{options[:otp_expires]}"})
  end

end
