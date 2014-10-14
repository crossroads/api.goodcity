class FlowdockNotification < ActionMailer::Base
  default from: ENV['EMAIL_FROM']

  def otp(token)
    subject = "SMS pin code"
    code = token.otp_code
    expiry = token.otp_code_expiry.strftime("%A %b %e %H:%M")
    body = I18n.t('twilio.sms_verification_pin', pin: code, expiry: expiry)
    email = ENV['FLOWDOCK_EMAIL']
    unless email.present?
      Rails.logger.warn("ENV['FLOWDOCK_EMAIL'] is not defined. Will not send flowdock notification email.")
      return
    end
    mail(to: email, subject: subject) do |format|
      format.text { render plain: body }
    end
  end

end
