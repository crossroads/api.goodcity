# frozen_String_literal: true

FactoryBot.define do
  factory :order do
    state               { submitted }
    submitted_at        { Time.now }
    description         { FFaker::Lorem.sentence }
    purpose_description { FFaker::Lorem.sentence }

    detail_type     { 'GoodCity' }
    people_helped   { rand(10) + 1 }
    booking_type    { create :booking_type, :online_order }
    association     :stockit_organisation
    association     :stockit_activity
    association     :organisation
    association     :stockit_contact
    association     :beneficiary
    association     :country
    association     :district

    trait :shipment do
      detail_type   { 'Shipment' }
      shipment_date { Date.current }
    end

    trait :carry_out do
      detail_type   { 'CarryOut' }
      shipment_date { Date.current }
    end

    trait :stockit_local_order do
      detail_type   { 'StockitLocalOrder' }
      shipment_date { Date.current }
    end

    trait :with_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_requested, :with_inventory_record, order: order)
        order.save
      end
    end

    trait :with_designated_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_designated, :with_inventory_record, order: order)
        order.save
      end
    end

    trait :with_cancelled_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_cancelled, :with_inventory_record, order: order)
        order.save
      end
    end

    trait :with_dispatched_orders_packages do
      after(:create) do |order|
        order.orders_packages << create_list(:orders_package, 3, :with_state_dispatched, :with_inventory_record, order: order)
        order.save
      end
    end

    trait :with_goodcity_requests do
      after(:create) do |order|
        order.goodcity_requests << create_list(:goodcity_request, 1, order: order)
        order.save
      end
    end

    trait :with_order_transport_ggv do
      association :order_transport, transport_type: 'ggv', strategy: :build
    end

    trait :with_order_transport_self do
      association :order_transport, transport_type: 'self', strategy: :build
    end

    trait :with_state_submitted do
      state { 'submitted' }
    end

    trait :with_state_processing do
      state { 'processing' }
      processed_at { Time.now }
      with_process_checklist
    end

    trait :with_state_awaiting_dispatch do
      state                { 'awaiting_dispatch' }
      processed_at         { Time.now }
      process_completed_at { Time.now }
      with_process_checklist
    end

    trait :with_state_dispatching do
      state                { 'dispatching' }
      processed_at         { Time.now }
      process_completed_at { Time.now }
      dispatch_started_at  { Time.now }
      with_process_checklist
    end

    trait :with_state_draft do
      state { 'draft' }
    end

    trait :with_state_cancelled do
      state        { 'cancelled' }
      processed_at { Time.now }
      cancelled_at { Time.now }
      cancel_reason { "Client didn't turn up" }
      cancellation_reason_id { create(:cancellation_reason, :no_show).id }
    end

    trait :with_state_closed do
      state                { 'closed' }
      processed_at         { Time.now }
      process_completed_at { Time.now }
      dispatch_started_at  { Time.now }
      closed_at            { Time.now }
      with_process_checklist
    end

    trait :awaiting_dispatch do
      state { 'awaiting_dispatch' }
      with_processed_by
      with_process_checklist
      with_process_completed_by
      process_completed_at { Time.now }
    end

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end

    trait :with_processed_by do
      association :processed_by, factory: :user, strategy: :build
      processed_at { Time.now }
    end

    trait :with_process_completed_by do
      association :process_completed_by, factory: :user, strategy: :build
      with_process_checklist
    end

    trait :with_process_checklist do
      process_checklists { ProcessChecklist.for_booking_type(booking_type) }
    end

    trait :with_closed_by do
      association :closed_by, factory: :user, strategy: :build
      with_processed_by
      with_process_checklist
      with_process_completed_by
    end

  end

  factory :online_order, parent: :order do
    booking_type { create :booking_type, :online_order }
    with_order_transport_ggv
  end

  factory :appointment, parent: :order do
    booking_type { create :booking_type, :appointment }
    with_order_transport_self
  end

end
