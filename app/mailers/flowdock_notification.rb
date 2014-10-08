class FlowdockNotification < ActionMailer::Base
  default from: ENV['EMAIL_FROM']

  def otp(otp)
    subject = "SMS pin code"
    body = I18n.t('twilio.sms_verification_pin', pin: otp[:otp_code], expiry: otp[:otp_code_expiry])
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
