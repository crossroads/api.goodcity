FactoryGirl.define do
  factory :role do
    name            { %w( Reviewer Supervisor Administrator ).sample }
    initialize_with { Role.find_or_initialize_by(name: name) } # limits us to our sample of permissions

    transient do
      permissions { %w(can_manage_offers, can_manage_packages)}
    end

    trait :with_can_destroy_contacts_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_destroy_contacts')
      end
    end

    trait :with_dynamic_permission do
      after(:create) do |role, evaluator|
        evaluator.permissions.each do |permission|
          role.permissions << (create :permission, name: permission)
        end
      end
    end

    trait :with_can_manage_offers_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_offers')
      end
    end

    trait :with_can_manage_users_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_users')
      end
    end

    trait :with_can_destroy_contacts_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_destroy_contacts')
      end
    end

    trait :with_can_manage_holidays_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_holidays')
      end
    end

    trait :with_can_manage_messages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_messages')
      end
    end

    trait :with_can_manage_offers_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_offers')
      end
    end

    trait :with_can_add_package_types_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_add_package_types')
      end
    end

    trait :with_can_manage_items_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_items')
      end
    end

    trait :with_can_create_and_read_messages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_create_and_read_messages')
      end
    end

    trait :with_can_read_or_modify_user_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_read_or_modify_user')
      end
    end

    trait :with_can_manage_packages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_packages')
      end
    end

    trait :with_can_manage_deliveries do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_deliveries')
      end
    end

    trait :with_can_manage_orders_packages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_orders_packages')
      end
    end

    trait :with_can_manage_packages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_packages')
      end
    end

    trait :with_can_manage_organisations_users_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_organisations_users')
      end
    end

    trait :with_can_check_organisations_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_check_organisations')
      end
    end

    trait :with_can_manage_items_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_items')
      end
    end

    trait :with_can_read_or_modify_user_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_read_or_modify_user')
      end
    end

    trait :with_can_manage_orders_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_orders')
      end
    end

    trait :with_can_manage_orders_packages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_orders_packages')
      end
    end

    trait :with_can_manage_images_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_images')
      end
    end

    trait :with_can_access_packages_locations_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_access_packages_locations')
      end
    end

    trait :with_can_manage_locations_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_locations')
      end
    end
  end

  factory :reviewer_role, parent: :role do
    name 'Reviewer'
  end

  factory :supervisor_role, parent: :role do
    name 'Supervisor'
  end

  factory :administrator_role, parent: :role do
    name 'Administrator'
  end

  factory :system_role, parent: :role do
    name 'System'
  end

  factory :api_write_role, parent: :role do
    name 'api-write'
  end

  factory :charity_role, parent: :role do
    name 'Charity'
  end
end
