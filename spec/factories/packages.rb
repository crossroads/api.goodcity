FactoryGirl.define do
  factory :package do
    # quantity              { rand(10) + 1 }
    quantity              5
    length                { rand(199) + 1 }
    width                 { rand(199) + 1 }
    height                { rand(199) + 1 }
    notes                 { FFaker::Lorem.paragraph }
    state                 'expecting'
    # received_quantity     10
    received_quantity     5

    received_at nil
    rejected_at nil

    association :package_type

    trait :with_item do
      association :item
    end

    trait :with_inventory_number do
      inventory_number      { InventoryNumber.next_code }
    end

    trait :package_with_locations do
      after(:create) do |package|
        package_location = create :packages_location, package: package, quantity: package.received_quantity
        package.location_id = package_location.location_id
        package.save
      end
    end

    trait :stockit_package do
      with_inventory_number
      stockit_id { rand(1000) + 1 }
      # sequence(:stockit_id) { |n| n }
    end

    trait :with_set_item do
      stockit_package
      item
      set_item_id { item.id }
    end

    trait :received do
      package_with_locations
      stockit_package
      state "received"
      received_at { Time.now }
    end

    trait :published do
      with_inventory_number
      allow_web_publish true
    end

    trait :with_lightly_used_donor_condition do
      donor_condition { create(:donor_condition, name_en: "Lightly Used") }
    end

    factory :browseable_package, traits: [:published, :with_inventory_number, :received]

  end
end
