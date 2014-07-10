class AuthToken < ActiveRecord::Base
  belongs_to :user
  has_one_time_password

  # Code to add the otp_secret_key in the auth_token
  # user_otp =user.auth_tokens.create(user_id: 35)

  # Code to generate the opt code
  # user_otp.otp_code

  # Code to authenticate the otp_code
  # user_otp.authenticate_otp(VALUE)
end
