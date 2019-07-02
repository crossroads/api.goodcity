FactoryBot.define do
  factory :requested_package do
    association :user
    association :package
  end

  trait :with_available_package do
    after(:create) do |requested_package, evaluator|
      requested_package.package.reload
      requested_package.package.allow_web_publish = true
      requested_package.package.save
    end
  end
end
