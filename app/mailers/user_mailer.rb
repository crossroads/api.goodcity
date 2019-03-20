class UserMailer < ApplicationMailer
  default from: ENV["FROM_EMAIL"]

  def send_pin_email(user)
    @user = user
    @pin = user.most_recent_token.otp_code
    mail(to: @user.email, subject: "GoodCity.HK pin code")
  end
end
