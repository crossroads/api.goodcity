# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :auth_token do
    association :user

    otp_code 903920
    otp_code_expiry { Date.today + 1.days }
    otp_secret_key  { User.auth_token.otp_secret_key }
    user_id 1
  end
end
