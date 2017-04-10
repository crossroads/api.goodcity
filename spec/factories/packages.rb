FactoryGirl.define do
  factory :package do
    quantity              { rand(10) + 1 }
    length                { rand(199) + 1 }
    width                 { rand(199) + 1 }
    height                { rand(199) + 1 }
    notes                 { FFaker::Lorem.paragraph }
    state                 'expecting'
    received_quantity     10

    received_at nil
    rejected_at nil

    association :package_type

    trait :with_item do
      association :item
    end

    trait :with_inventory_number do
      inventory_number      { generate(:inventory_number) }
    end

    trait :package_with_locations do
      after(:create) do |package|
        package_location = create :packages_location, package: package, quantity: package.received_quantity
        package.location_id = package_location.location_id
        package.save
      end
    end

    trait :stockit_package do
      inventory_number      { generate(:inventory_number) }
      sequence(:stockit_id) { |n| n }
    end

    trait :with_set_item do
      inventory_number      { generate(:inventory_number) }
      sequence(:stockit_id) { |n| n }
      item
      set_item_id { item.id }
    end

    trait :received do
      package_with_locations
      state "received"
      received_at { Time.now }
      inventory_number      { generate(:inventory_number) }
      sequence(:stockit_id) { |n| n }
    end

    trait :published do
      allow_web_publish true
    end
  end
end
