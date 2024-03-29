FactoryBot.define do
  factory :shareable do
    allow_listing { true }
    expires_at    { nil }
    notes         { "Notes" }
    notes_zh_tw   { notes }
    association   :created_by, factory: :user
    association   :resource, factory: :offer
    
    trait :offer do
      association :resource, factory: :offer
    end
    trait :package do
      association :resource, factory: :package
    end
    trait :item do
      association :resource, factory: :item
    end
  end
end
