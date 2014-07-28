# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :auth_token do
    association :user
    otp_code {Faker.numerify("######")}
    otp_code_expiry { Date.today + 1.days }
  end

  factory :scenario_before_auth_token, parent: :auth_token do
    otp_code {521175}
    otp_code_expiry { Date.today + 10.hours }
  end
end
