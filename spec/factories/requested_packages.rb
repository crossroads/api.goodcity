FactoryBot.define do
  factory :requested_package do
    quantity { 1 }
    association :user
    association :package, :published
  end
end
