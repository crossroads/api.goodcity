class TwilioJob < ActiveJob::Base
  queue_as :high

  # e.g. options = { to: @user.mobile, body: body }
  def perform(options)
    if send_to_twilio?(options)
      client = Twilio::REST::Client.new(twilio_conf[:account_sid], twilio_conf[:auth_token])
      client.messages.create({ from: twilio_conf[:phone_number], risk_check: 'disable' }.merge(options))
      Rails.logger.info(class: self.class.name, msg: "SMS sent", mobile: options[:to], body: options[:body])
    elsif Rails.env.staging?
      # We'll send the SMS text via email to mailcatcher instead
      ActionMailer::Base.mail(from: ENV['EMAIL_FROM'], to: ENV['EMAIL_FROM'], subject: "SMS to #{options[:to]}", body: options[:body]).deliver
    end
  end
  
  private

  # Ensure
  # - we're in production
  # - we have a 'to' number (format: +85261016474)
  # - we don't send SMS to ourselves (can happen when Apple testers use our app)
  def send_to_twilio?(options)
    Rails.env.production? and \
    options[:to].present? and \
    options[:to] != twilio_from
  end

  # prefix with '+' if needed
  def twilio_from
    if twilio_conf[:phone_number].to_s.start_with?('+')
      twilio_conf[:phone_number]
    else
      "+#{twilio_conf[:phone_number]}"
    end
  end

  def twilio_conf
    @twilio_conf ||= Rails.application.secrets.twilio
  end

end
