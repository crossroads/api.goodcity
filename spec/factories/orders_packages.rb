# frozen_String_literal: true

FactoryBot.define do
  factory :orders_package do
    association   :order
    association   :package, :with_inventory_record
    association   :updated_by, factory: :user, strategy: :build
    state         { %w[requested cancelled designated received].sample }
    quantity      { 2 }

    trait :with_package_item do
      association :package, :with_item
    end

    trait :with_state_requested do
      state { 'requested' }
    end

    trait :with_state_designated do
      state { 'designated' }
    end

    trait :with_state_dispatched do
      dispatched_quantity { quantity }
      state { 'dispatched' }
      sent_on { Time.now }
    end

    trait :with_inventory_record do
      after(:create) do |orders_package|
        package = orders_package.package
        if orders_package.dispatched?
          create :packages_inventory, location: package.locations.first, package: package, source: orders_package, quantity: -1 * orders_package.quantity, action: 'dispatch'
        end
      end
    end
  end

  trait :with_state_requested do
    state { 'requested' }
  end

  trait :with_state_cancelled do
    state { 'cancelled' }
  end
end
