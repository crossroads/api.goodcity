FactoryBot.define do
  factory :user_favourite do
    persistent  { false }
    user      { |m| m.association(:user) }
    association :favourite, factory: :package_type
  end
end
