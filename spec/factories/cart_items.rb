FactoryBot.define do
  factory :cart_item do
    association :user
    association :package
  end

  trait :with_available_package do
    after(:create) do |cart_item, evaluator|
      cart_item.package.reload
      cart_item.package.allow_web_publish = true
      cart_item.package.save
    end
  end
end
