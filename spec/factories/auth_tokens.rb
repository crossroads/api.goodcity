# Read about factories at https://github.com/thoughtbot/factory_girl
FactoryGirl.define do
  factory :auth_token do
    association :user
    otp_code {Faker.numerify("######")}
    otp_code_expiry { Date.today + 1.days }
  end
end
