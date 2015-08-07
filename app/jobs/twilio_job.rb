class TwilioJob  < ActiveJob::Base
  queue_as :default

  # e.g. options = { to: @user.mobile, body: body }
  def perform(options)
    twilio_conf = Goodcity.config.twilio
    client = Twilio::REST::Client.new(twilio_conf.account_sid, twilio_conf.auth_token)
    client.account.messages.create( {from: twilio_conf.phone_number}.merge(options) )
  end
end
