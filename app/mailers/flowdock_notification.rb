class FlowdockNotification < ActionMailer::Base
  default from: ENV['EMAIL_FROM']

  def otp(otp_code)
    email = ENV['FLOWDOCK_EMAIL']
    if email.present?
      mail(to: email, subject: "SMS pin code") do |format|
        format.text { render plain: mail_text(otp_code) }
      end
    else
      Rails.logger.warn("ENV['FLOWDOCK_EMAIL'] is not defined. Will not send flowdock notification email.")
    end
  end

  def mail_text(otp_code)
    I18n.t('twilio.sms_verification_pin', pin: otp_code)
  end

end
