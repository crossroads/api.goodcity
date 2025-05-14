class TwilioJob < ActiveJob::Base
  queue_as :high

  # e.g. options = { to: @user.mobile, body: body }
  def perform(options)
    if send_to_twilio?(options)
      twilio_conf = Rails.application.secrets.twilio
      client = Twilio::REST::Client.new(twilio_conf[:account_sid], twilio_conf[:auth_token])
      client.messages.create({ from: twilio_conf[:phone_number] }.merge(options))
      Rails.logger.info(class: self.class.name, msg: "SMS sent", mobile: options[:to], body: options[:body])
    elsif Rails.env.staging?
      # We'll send the SMS text via email to mailcatcher instead
      ActionMailer::Base.mail(from: ENV['EMAIL_FROM'], to: ENV['EMAIL_FROM'], subject: "SMS to #{options[:to]}", body: options[:body]).deliver
    end
  end
  
  private

  # Easier rspec testing
  def send_to_twilio?(options)
    options[:to].present? and Rails.env.production?
  end

end
