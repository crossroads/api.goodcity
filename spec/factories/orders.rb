FactoryBot.define do
  factory :order do
    status   ["draft", "submitted", "processing", "closed", "cancelled"].sample
    state    ["draft", "submitted", "processing", "closed", "cancelled"].sample

    code          { generate(:code) }
    description     FFaker::Lorem.sentence
    purpose_description FFaker::Lorem.sentence
    stockit_id      nil
    detail_type     "GoodCity"
    people_helped   { rand(10) + 1 }
    association     :stockit_organisation
    association     :stockit_activity
    association     :organisation
    association     :stockit_contact
    association     :beneficiary
    association     :country
    association     :district
    association     :booking_type

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

    trait :with_goodcity_requests do
      goodcity_requests { create_list :goodcity_request, 1}
    end

    trait :with_stockit_id do
      sequence(:stockit_id) { |n| n }
    end

    trait :with_state_submitted do
      state "submitted"
    end

    trait :with_status_processing do
      status "processing"
    end

    trait :with_state_processing do
      state "processing"
    end

    trait :with_state_awaiting_dispatch do
      state "awaiting_dispatch"
    end

    trait :with_state_dispatching do
      state "dispatching"
    end

    trait :with_state_draft do
      state "draft"
    end

    trait :with_state_cancelled do
      state "cancelled"
    end

    trait :with_state_closed do
      state "closed"
    end

    trait :awaiting_dispatch do
      state 'awaiting_dispatch'
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
end
