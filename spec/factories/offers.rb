# frozen_String_literal: true

FactoryBot.define do
  factory :offer do
    language       { 'en' }
    state          { 'draft' }
    origin         { 'web' }
    stairs         { [false, true].sample }
    parking        { [false, true].sample }
    estimated_size { [1,2,3,4].sample.to_s }
    notes          { "Notes" }
    saleable       { true }
    association    :created_by, factory: :user

    trait :with_district do
      association    :district
    end

    trait :admin_offer do
      scheduled
      reviewed_at { Time.now }
      created_by  { nil }
    end

    trait :submitted do
      submitted_at { Time.now }
      state        { 'submitted' }
    end

    trait :under_review do
      submitted
      reviewed_at { Time.now }
      state       { 'under_review' }
      association :reviewed_by, :reviewer, factory: :user
    end

    trait :reviewed do
      under_review
      review_completed_at { Time.now }
      with_transport
      state               { 'reviewed' }
    end

    trait :scheduled do
      reviewed
      with_delivery
      state         { 'scheduled' }
    end

    trait :receiving do
      scheduled
      start_receiving_at { Time.now }
      association        :received_by, :reviewer, factory: :user
      state              { 'receiving' }
    end

    trait :received do
      receiving
      received_at { Time.now }
      state       { 'received' }
    end

    trait :closed do
      received
      association :closed_by, :reviewer, factory: :user
      state       { 'closed' }
    end

    trait :cancelled do
      reviewed
      cancelled_at  { Time.now }
      state         { 'cancelled' }
      association   :cancellation_reason
      cancel_reason { 'This offer is cancelled because it is not suitable.' }
    end

    trait :inactive do
      submitted
      inactive_at { Time.now }
      state       { 'inactive' }
    end

    trait :with_items do
      transient do
        items_count { rand(3)+1 }
      end
      after(:create) do |offer, evaluator|
        evaluator.items_count.times { create :item, :with_packages, :with_images, offer: offer }
      end
    end

    # Used by lib/tasks/db/demo.rake
    trait :with_demo_items do
      transient do
        items_count { rand(3)+1 }
      end
      after(:create) do |offer, evaluator|
        evaluator.items_count.times { create :demo_item, offer: offer }
      end
    end

    trait :with_delivery do
      transient do
        delivery_type { [:crossroads_delivery, :drop_off_delivery].sample }
      end
      after(:create) do |offer, evaluator|
        create evaluator.delivery_type, offer: offer
      end
    end

    trait :with_messages do
      transient do
        messages_count { 1 }
      end
      after(:create) do |offer, evaluator|
        create_list(:message, evaluator.messages_count, :reviewer_message, messageable: offer)
      end
    end

    trait :paranoid do
      state      { 'submitted' }
      items      { [create(:item)] }
    end

    trait :with_transport do
      association    :gogovan_transport
      association    :crossroads_transport
    end
  end
end
