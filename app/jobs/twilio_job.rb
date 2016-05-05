class TwilioJob  < ActiveJob::Base
  queue_as :default

  rescue_from(Twilio::REST::RequestError) do
    retry_job wait: 30.seconds
  end

  # e.g. options = { to: @user.mobile, body: body }
  def perform(options)
    twilio_conf = Rails.application.secrets.twilio
    client = Twilio::REST::Client.new(twilio_conf['account_sid'], twilio_conf['auth_token'])
    client.account.messages.create( {from: twilio_conf['phone_number']}.merge(options) )
  end
end
