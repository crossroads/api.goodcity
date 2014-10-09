# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact do
    name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
  end
end
