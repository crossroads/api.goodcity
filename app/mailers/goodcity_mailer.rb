# frozen_string_literal: true

# GoodcityMailer - to send system wide email
class GoodcityMailer < ApplicationMailer
  default from: GOODCITY_FROM_EMAIL

  def send_pin_email
    @user = User.find_by(id: params[:user_id])
    @pin = @user.most_recent_token.otp_code
    mail(to: @user.email, subject: I18n.t('email.subject.login'))
  end
end
