# frozen_String_literal: true

# USAGE:
#   create(:user)
#   create(:user, :order_administrator)
#   create(:user, :with_order_administrator_role)  # has the role but no permissions
#   create(:user, :with_can_manage_packages_permission) # when you don't care which role the user gets (they'll get one)
#   create(:user, :with_can_manage_packages_permission, role_name: "Supervisor") # can specify role if permission belongs to more than one
#   create(:user, :with_supervisor_role, :with_can_manage_packages_permission) # alternative way to specify role

# You MUST specify role_name when using more than one permission to avoid getting permissions with mixed roles:
#   create(:user, :with_can_manage_packages_permission, :with_can_manage_offers_permission, role_name: "Supervisor")
#   create(:user, :with_supervisor_role, :with_can_manage_packages_permission, :with_can_manage_offers_permission)
#

FactoryBot.define do
  factory :user, aliases: [:sender] do
    association :address

    title                { ["Mr", "Mrs", "Miss", "Ms"].sample }
    first_name           { FFaker::Name.first_name }
    last_name            { FFaker::Name.last_name }
    mobile               { generate(:mobile) }
    email                { "#{rand(1000)}#{FFaker::Internet.email}" }
    last_connected       { 2.days.ago }
    last_disconnected    { 1.day.ago }
    disabled             { false }
    sms_reminder_sent_at { nil }
    initialize_with      { User.find_or_initialize_by(mobile: mobile) }

    association :image

    transient do
      sequence(:role_name)    { |n| generate(:permissions_roles).keys.sort[n%generate(:permissions_roles).keys.size] }
      roles_and_permissions { }
    end

    # Role specific users. create(:user, :order_administrator)
    # No permissions are created
    FactoryBot.generate(:permissions_roles).keys.each do |role|
      trait role.parameterize.underscore.to_sym do
        after(:create) do |user|
          r = create("#{role.parameterize.underscore}_role")
          user.roles << r unless user.roles.include?(r)
        end
      end
    end

    # Role specific users: create(:user, :with_order_administrator_role)
    # No permissions are created
    FactoryBot.generate(:permissions_roles).keys.each do |role|
      trait "with_#{role.parameterize.underscore}_role".to_sym do
        after(:create) do |user, evaluator|
          r = create("#{role.parameterize.underscore}_role")
          unless user.roles.include?(r)
            create :user_role, user: user, role: r, expires_at: evaluator.role_expiry
          end
        end
        transient do
          # ensures if multiple permission traits are used, that they get assigned to the same role
          role_name { role.parameterize.underscore }
          role_expiry { 5.days.from_now }
        end
      end
    end

    # create(:user, :with_<insert permission name>_permission)
    # If more than 1 role has the same permission, then only 1 role will be defined
    # However, you can set the particular role by using the 'role_name parameter'
    # E.g. create(:user, :with_can_manage_packages, role_name: "Supervisor")
    # in order to avoid a user with role Reviewer AND Supervisor
    FactoryBot.generate(:permissions_roles).each do |role_name, permissions|
      permissions.each do |permission|
        trait "with_#{permission}_permission".to_sym do
          after(:create) do |user, evaluator|
            # create(:supervisor_role, :with_can_manage_packages_permission)
            r = create("#{(evaluator.role_name || role_name).parameterize.underscore}_role".to_sym, "with_#{permission}_permission".to_sym)
            user.roles << r unless user.roles.include?(r)
          end
        end
      end
    end

    trait :no_mobile do
      mobile { nil }
      is_mobile_verified { false }
    end

    trait :system do
      first_name { 'GoodCity' }
      last_name { 'Team' }
      mobile { SYSTEM_USER_MOBILE }
      after(:create) do |user|
        user.roles << create(:system_role)
      end
    end

    trait :donor do
      is_mobile_verified { true }
    end

    trait :charity do
      with_email
      after(:create) do |user|
        user.organisations_users << (create :organisations_user, :approved, user_id: user.id)
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

    trait :with_token do
      after(:create) do |user, evaluator|
        create_list(:auth_token, 1)
      end
    end
  end
end
