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

  def sms_verification_pin(user)
    TWILIO_CLIENT.account.sms.messages.create({
        from: TWILIO_CONF['twilio_phone_number'],
        to: user.mobile,
        body: "your pin is 1111"})
  end
end
