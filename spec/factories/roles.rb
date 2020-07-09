FactoryBot.define do

  factory :role do
    name            { generate(:permissions_roles).keys.sample }
    level           10
    initialize_with { Role.find_or_initialize_by(name: name) } # limits us to our sample of permissions

    transient do
      permissions { %w(can_manage_offers, can_manage_packages)}
    end

    YAML.load_file("#{Rails.root}/db/roles.yml").each do |role, attrs|
      factory "#{role.parameterize.underscore}_role", parent: :role do
        name role
        level attrs[:level]
      end
    end

    trait :with_dynamic_permission do
      after(:create) do |role, evaluator|
        evaluator.permissions.each do |permission|
          role.permissions << (create :permission, name: permission)
        end
      end
    end

    trait :charity_role do
      name { 'Charity' }
      after(:create) do |role|
        %w[can_login_to_browse can_search_browse_packages can_create_goodcity_requests].map do |permission|
          role.permissions << (create :permission, name: permission)
        end
      end
    end

    trait :with_can_add_or_remove_inventory_number do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_add_or_remove_inventory_number')
      end
    end

    trait :with_can_destroy_contacts_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_destroy_contacts')
      end
    end

    trait :with_can_manage_package_detail_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_package_detail')
      end
    end

    trait :with_can_remove_offers_packages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_remove_offers_packages')
      end
    end

    trait :with_can_manage_users_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_users')
      end
    end

    trait :with_can_manage_holidays_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_holidays')
      end
    end

    trait :with_can_read_versions_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: "can_read_versions")
      end
    end

    trait :with_can_manage_messages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_messages')
      end
    end

    trait :with_can_add_package_types_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_add_package_types')
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

    trait :with_can_read_or_modify_user_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_read_or_modify_user')
      end
    end

    trait :with_can_create_user_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_create_donor')
      end
    end

    trait :with_can_manage_orders_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_orders')
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

    trait :with_can_manage_offers_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_offers')
      end
    end

    trait :with_can_manage_items_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_items')
      end
    end

    trait :with_can_manage_goodcity_requests_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_goodcity_requests')
      end
    end

    trait :with_can_create_and_read_messages_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_create_and_read_messages')
      end
    end

    trait :with_can_manage_settings do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_manage_settings')
      end
    end

    trait :with_can_access_printers do
      after(:create) do |role|
        role.permissions << (create :permission, name: "can_access_printers")
      end
    end

    trait :with_can_access_orders_process_checklists do
      after(:create) do |role|
        role.permissions << (create :permission, name: "can_access_orders_process_checklists")
      end
    end

    trait :with_can_disable_user do
      after(:create) do |role|
        role.permissions << (create :permission, name: "can_disable_user")
      end
    end

    trait :with_can_manage_user_roles do
      after(:create) do |role|
        role.permissions << (create :permission, name: "can_manage_user_roles")
      end
    end
  end
end
