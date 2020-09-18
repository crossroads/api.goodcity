FactoryBot.define do
  factory :user_role do
    association :user
    association :role
    expires_at { 5.days.from_now }
  end
end
