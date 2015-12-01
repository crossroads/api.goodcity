class FlowdockNotification < ActionMailer::Base
  default from: ENV['EMAIL_FROM']

  def otp(token_id)
    token = AuthToken.find_by(id: token_id)

    if(token)
      email = ENV['FLOWDOCK_EMAIL']
      unless email.present?
        Rails.logger.warn("ENV['FLOWDOCK_EMAIL'] is not defined. Will not send flowdock notification email.")
        return
      end
      mail(to: email, subject: "SMS pin code") do |format|
        format.text { render plain: mail_text }
      end
    else
      FlowdockNotification.otp(token_id).deliver_later
    end
  end

  def mail_text
    code = token.otp_code
    expiry = token.otp_code_expiry.strftime("%A %b %e %H:%M")
    I18n.t('twilio.sms_verification_pin', pin: code, expiry: expiry)
  end

end
