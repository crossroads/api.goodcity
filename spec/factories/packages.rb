# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :package do
    quantity    1
    length      { rand(199) + 1 }
    width       { rand(199) + 1 }
    height      { rand(199) + 1 }
    notes       { Faker::Lorem.paragraph }

    received_at nil
    rejected_at nil

    association :package_type, factory: :item_type

    trait :with_item do
      association :item
    end
  end
end
