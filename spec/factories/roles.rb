# frozen_String_literal: true

# USAGE:
#   create(:role)                   # empty
#   create(:reviewer_role)          # named, no permissions specified
#   create(:order_fulfilment_role)  # named, no permissions specified
#   create(:reviewer_role, :with_can_manage_offers_permission) # specify 1 permission
#   create(:reviewer_role, :with_can_manage_offers_permission, :with_can_manage_messages_permission) # specify multiple permissions
#
FactoryBot.define do
  factory :role do
    sequence(:name) { |n| generate(:permissions_roles).keys.sort[n%generate(:permissions_roles).keys.size] }
    level           { 10 }
    initialize_with { Role.find_or_initialize_by(name: name) } # avoid duplicate roles

    transient do
      permissions { %w(can_manage_offers, can_manage_packages)}
    end

    # create(:reviewer_role) # No permissions, just the role
    YAML.load_file("#{Rails.root}/db/roles.yml").each do |role, attrs|
      factory "#{role.parameterize.underscore}_role", parent: :role do
        name { role }
        level { attrs[:level] }
      end
    end

    # create(:reviewer_role, :with_permissions, permissions: ['can_manage_offers', 'can_manage_messages'])
    trait :with_permissions do
      after(:create) do |role, evaluator|
        evaluator.permissions.each do |permission|
          p = create(:permission, name: permission)
          role.permissions << p unless role.permissions.include?(p)
        end
      end
    end

    # create(:reviewer_role, :with_can_manage_offers_permission)
    # create(:reviewer_role, :with_can_manage_offers_permission, :with_can_manage_messages_permission)
    YAML.load_file("#{Rails.root}/db/permissions_roles.yml").each do |role_name, permissions|
      permissions.each do |permission|
        trait "with_#{permission}_permission".to_sym do
          after(:create) do |role|
            p = create(:permission, name: permission)
            role.permissions << p unless role.permissions.include?(p)
          end
        end
      end
    end
  end
end
