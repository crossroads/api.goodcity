FactoryBot.define do
  factory :user_role do
    association :user
    association :role
    expiry_date { 5.days.from_now }
  end
end
