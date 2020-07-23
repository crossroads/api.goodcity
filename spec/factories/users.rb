# USAGE:
#   create(:user)
#   create(:user, :reviewer)
#   create(:user, :order_administrator)
#
FactoryBot.define do
  factory :user, aliases: [:sender] do
    association :address

    first_name { FFaker::Name.first_name }
    last_name { FFaker::Name.last_name }
    mobile { generate(:mobile) }
    email { FFaker::Internet.email }
    last_connected { 2.days.ago }
    last_disconnected { 1.day.ago }
    disabled { false }
    sms_reminder_sent_at { nil }
    initialize_with { User.find_or_initialize_by(mobile: mobile) }

    association :image

    transient do
      role_name { generate(:permissions_roles).keys.sample }
      roles_and_permissions { }
    end

    # Role specific users. create(:user, :order_administrator)
    FactoryBot.generate(:permissions_roles).keys.each do |role|
      trait role.parameterize.underscore.to_sym do
        after(:create) do |user|
          user.roles << create("#{role.parameterize.underscore}_role")
        end
      end
    end

    trait :user_with_no_mobile do
      mobile { nil }
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

    trait :with_can_manage_stocktakes_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_stocktakes_permission, name: evaluator.role_name)
      end
    end

    trait :with_can_manage_stocktake_revisions_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_stocktake_revisions_permission, name: evaluator.role_name)
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

    trait :with_can_remove_offers_packages_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_remove_offers_packages_permission, name: evaluator.role_name)
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

    trait :with_can_manage_goodcity_requests_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_goodcity_requests_permission, name: evaluator.role_name)
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

    trait :with_can_create_user_permission do
      after(:create) do |user, evaluator|
        user.roles << (create "#{evaluator.role_name.parameterize.underscore}_role".to_sym, :with_can_create_user_permission)
      end
    end

    trait :with_can_manage_package_detail_permission do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_package_detail_permission, name: evaluator.role_name)
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

    trait :with_can_manage_settings do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_manage_settings, name: evaluator.role_name)
      end
    end

    trait :with_can_access_printers do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_access_printers, name: evaluator.role_name)
      end
    end

    trait :with_can_access_orders_process_checklists do
      after(:create) do |user, evaluator|
        user.roles << (create :role, :with_can_access_orders_process_checklists, name: evaluator.role_name)
      end
    end

    trait :with_can_disable_user do
      after(:create) do |user, evaluator|
        user.roles << (create "#{evaluator.role_name.parameterize.underscore}_role".to_sym,  :with_can_disable_user)
      end
    end

    trait :with_can_manage_user_roles do
      after(:create) do |user, evaluator|
        user.roles << (create "#{evaluator.role_name.parameterize.underscore}_role".to_sym,  :with_can_manage_user_roles)
      end
    end

    trait :api_user do
      after(:create) do |user|
        user.roles << create(:api_write_role)
      end
    end

    trait :stockit_user do
      first_name "Stockit"
      last_name "User"
    end

    trait :system do
      first_name "GoodCity"
      last_name "Team"
      mobile SYSTEM_USER_MOBILE
      after(:create) do |user|
        user.roles << create(:system_role)
      end
    end

    trait :title do
      title { ["Mr", "Mrs", "Miss", "Ms"].sample }
    end

    trait :with_organisation do
      after(:create) do |user|
        user.organisations << create(:organisation)
      end
    end

    trait :with_offer do
      after(:create) do |user|
        user.offers << create(:offer)
      end
    end

    trait :with_email do
      email { FFaker::Internet.email }
    end

    trait :with_requested_packages do
      after(:create) do |user, evaluator|
        user.requested_packages << (create :requested_package, user_id: user.id)
      end
    end
  end

  factory :user_with_token, parent: :user do
    mobile { generate(:mobile) }
    after(:create) do |user|
      user.auth_tokens << create(:scenario_before_auth_token)
    end
  end

end
