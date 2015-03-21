# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user, aliases: [:sender] do
    association :address

    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    mobile     { generate(:mobile) }

    association :image

    trait :reviewer do
      association :permission, factory: :reviewer_permission
    end

    trait :supervisor do
      association :permission, factory: :supervisor_permission
    end

    trait :administrator do
      association :permission, factory: :administrator_permission
    end
  end

  factory :user_with_token, parent: :user do
    mobile { generate(:mobile) }
    after(:create) do |user|
      user.auth_tokens << create(:scenario_before_auth_token)
    end
  end

  factory :system_user, parent: :user do
    first_name "GoodCity"
    last_name  "Team"
    mobile     SYSTEM_USER_MOBILE
    association :permission, factory: :reviewer_permission
    initialize_with { User.find_or_initialize_by(mobile: SYSTEM_USER_MOBILE) } # only create one system user
  end

end
