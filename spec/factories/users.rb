# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    mobile     { Faker::PhoneNumber.phone_number }

    factory :reviewer do
      permissions { [create(:reviewer_permission)] }
    end

    factory :supervisor do
      permissions { [create(:supervisor_permission)] }
    end

    factory :administrator do
      permissions { [create(:administrator_permission)] }
    end
  end
end
