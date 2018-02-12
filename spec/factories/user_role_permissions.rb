FactoryGirl.define do
  factory :user_role_permission do
    association :user
    association :role
    association :permission
  end
end
