# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :auth_token do
    verification_pin 1
    verification_pin_expiry "2014-07-10 23:45:42"
    secure_token "MyString"
    user_id 1
  end
end
