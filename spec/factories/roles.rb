FactoryGirl.define do

  factory :role do
    name            { %w( Reviewer Supervisor Administrator ).sample }
    initialize_with { Role.find_or_initialize_by(name: name) } # limits us to our sample of permissions

    trait :with_can_destroy_contacts_permission do
      after(:create) do |role|
        role.permissions << (create :permission, name: 'can_destroy_contacts')
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
