# frozen_string_literal: true

# GoodcityMailer - to send system wide email
class GoodcityMailer < ApplicationMailer
  def send_pin_email
    @pin = @user.most_recent_token.otp_code
    mail(to: @user.email, subject: I18n.t('email.subject.login'))
  end
end
