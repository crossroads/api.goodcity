# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :auth_token do
    association :user
    otp_code_expiry { Time.now + 10.hours }
  end

  factory :scenario_before_auth_token, parent: :auth_token do
    otp_code_expiry { Time.now + Rails.application.secrets.token['otp_code_validity'] }
  end
end
