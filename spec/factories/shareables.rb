FactoryBot.define do
  factory :shareable do
    allow_listing { true }
    expires_at { nil }
    association :created_by, factory: :user
    association :resource, factory: :offer
  end
end
