# frozen_String_literal: true

FactoryBot.define do
  factory :order do
    state    { %w[draft submitted processing closed cancelled].sample }

    description     { FFaker::Lorem.sentence }
    purpose_description { FFaker::Lorem.sentence }

    detail_type     { 'GoodCity' }
    people_helped   { rand(10) + 1 }
    shipment_date    { Date.current }
    booking_type    { create :booking_type, :online_order }
    association     :stockit_organisation
    association     :stockit_activity
    association     :organisation
    association     :stockit_contact
    association     :beneficiary
    association     :country
    association     :district

    trait :shipment do
      detail_type { 'Shipment' }
    end

    trait :carry_out do
      detail_type  { 'CarryOut' }
    end

    trait :stockit_local_order do
      detail_type  { 'StockitLocalOrder' }
    end

    trait :with_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_requested)
        order.save
      end
    end

    trait :with_designated_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_designated)
        order.save
      end
    end

    trait :with_cancelled_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_cancelled)
        order.save
      end
    end

    trait :with_dispatched_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_dispatched)
        order.save
      end
    end

    trait :with_goodcity_requests do
      goodcity_requests { create_list :goodcity_request, 1}
    end

    trait :with_state_submitted do
      state { 'submitted' }
    end

    trait :with_state_processing do
      state { 'processing' }
    end

    trait :with_state_awaiting_dispatch do
      state { 'awaiting_dispatch' }
    end

    trait :with_state_dispatching do
      state { 'dispatching' }
    end

    trait :with_state_draft do
      state { 'draft' }
    end

    trait :with_state_cancelled do
      state { 'cancelled' }
    end

    trait :with_state_closed do
      state { 'closed' }
    end

    trait :awaiting_dispatch do
      state { 'awaiting_dispatch' }
      :with_processed_by
      processed_at { Time.now }
      :with_process_completed_by
      process_completed_at { Time.now }
    end

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end

    trait :with_processed_by do
      association :processed_by, factory: :user, strategy: :build
    end

    trait :with_closed_by do
      association :closed_by, factory: :user, strategy: :build
    end

    trait :with_process_completed_by do
      association :process_complted_by, factory: :user, strategy: :build
    end
  end

  factory :online_order, parent: :order do
    booking_type { create :booking_type, :online_order }
  end

  factory :appointment, parent: :order do
    booking_type { create :booking_type, :appointment }
  end
end
