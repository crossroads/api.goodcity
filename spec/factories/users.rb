FactoryBot.define do
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

    transient do
      role_name { generate(:permissions_roles).keys.sample }
      roles_and_permissions {}
    end

    [:reviewer, :order_fulfilment, :supervisor, :administrator, :charity].each do |role|
      trait role do
        after(:create) do |user|
          user.roles << create("#{role}_role")
        end
      end
    end

    trait :with_multiple_roles_and_permissions do
      after(:create) do |user, evaluator|
        evaluator.roles_and_permissions.each_pair do |role_name, permissions|
          user.roles << create(:role, :with_dynamic_permission, name: role_name, permissions: permissions)
        end
      end
    end

    trait :with_can_add_or_remove_inventory_number do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_add_or_remove_inventory_number, name: evaluator.role_name)
      end
    end

    trait :with_can_destroy_contact_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_destroy_contacts_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_read_versions_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_read_versions_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_holidays_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_holidays_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_create_and_read_messages_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_create_and_read_messages_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_packages_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_packages_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_organisations_users_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_organisations_users_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_deliveries do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_deliveries, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_orders_packages_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_orders_packages_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_check_organisations_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_check_organisations_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_items_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_items_permission, name: evaluator.role_name)
      end
    end

    trait :can_mange_goodcity_requests_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :can_mange_goodcity_requests_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_messages_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_messages_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_offers_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_offers_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_add_package_types_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_add_package_types_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_read_or_modify_user_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_read_or_modify_user_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_images_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_images_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_access_packages_locations_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_access_packages_locations_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_orders_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_orders_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_locations_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_locations_permission, name: evaluator.role_name)
      end
    end

    trait :api_user do
      after(:create) do |user|
        user.roles << create(:api_write_role)
      end
    end

    trait :stockit_user do
      first_name "Stockit"
      last_name  "User"
    end

    trait :system do
      first_name "GoodCity"
      last_name  "Team"
      mobile     SYSTEM_USER_MOBILE
      after(:create) do |user|
        user.roles << create(:system_role)
      end
    end

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
