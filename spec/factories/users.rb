# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user, aliases: [:sender] do
    association :address

    first_name        { FFaker::Name.first_name }
    last_name         { FFaker::Name.last_name }
    mobile            { generate(:mobile) }
    last_connected    { 2.days.ago }
    last_disconnected { 1.day.ago }
    disabled          { false }
    initialize_with   { User.find_or_initialize_by(mobile: mobile) }

    association :image

    trait :reviewer do
      after(:create) do |user|
        user.roles << create(:reviewer_role)
      end
    end

    trait :reviewer_with_can_manage_offers_permission do
      after(:create) do |user|
        user.roles << create(:reviewer_role, :with_can_manage_offers_permission)
      end
    end

    trait :supervisor do
      after(:create) do |user|
        user.roles << create(:supervisor_role)
      end
    end

    trait :administrator do
      after(:create) do |user|
        user.roles << create(:administrator_role)
      end
    end

    trait :api_user do
      after(:create) do |user|
        user.roles << create(:api_write_role)
      end
    end

    trait :system do
      first_name "GoodCity"
      last_name  "Team"
      mobile     SYSTEM_USER_MOBILE
      after(:create) do |user|
        user.roles << create(:system_role)
      end
      # association :role, factory: :system_role
    end

    trait :charity do
      after(:create) do |user|
        user.roles << create(:charity_role)
      end
    end

    # trait :reviewer do
    #   association :role, factory: :reviewer_role
    # end

    # trait :supervisor do
    #   association :role, factory: :supervisor_role
    # end

    # trait :administrator do
    #   association :role, factory: :administrator_role
    # end

    # trait :api_user do
    #   association :role, factory: :api_write_role
    # end

    # trait :charity do
    #   # association :permission, factory: :charity_permission
    # end

    trait :with_email do
      email { FFaker::Internet.email }
    end
  end

  factory :user_with_token, parent: :user do
    mobile { generate(:mobile) }
    after(:create) do |user|
      user.auth_tokens << create(:scenario_before_auth_token)
    end
  end

end
