# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user do
    association :address

    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    mobile     { Faker::PhoneNumber.phone_number }

    factory :reviewer do
      permission { create(:reviewer_permission) }
    end

    factory :supervisor do
      permission { create(:supervisor_permission) }
    end

    factory :administrator do
      permission { create(:administrator_permission) }
    end
  end

  factory :user_with_token, parent: :user do
    mobile {"+85211111111"}
    after(:create) do |user|
      user.auth_tokens << create(:scenario_before_auth_token)
    end
  end

  factory :user_with_correct_number, parent: :user do
    mobile {"+85211111111"}
  end

  factory :user_with_wrong_number, parent: :user do
    mobile {"+85211111112"}
  end
end
