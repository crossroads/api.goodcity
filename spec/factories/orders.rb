FactoryGirl.define do
  factory :order do
    status   ["draft", "submitted", "processing", "closed", "cancelled"].sample
    state    ["draft", "submitted", "processing", "closed", "cancelled"].sample

    code          { generate(:code) }
    description     FFaker::Lorem.sentence
    purpose_description FFaker::Lorem.sentence
    stockit_id      nil
    detail_type     "GoodCity"
    association     :stockit_organisation
    association     :stockit_activity
    association     :organisation
    association     :stockit_contact
    association     :country

    trait :with_orders_packages do
      orders_packages { create_list :orders_package, 3, :with_state_requested}
    end

    trait :with_state_submitted do
      state "submitted"
    end

    trait :with_status_processing do
      status "processing"
    end

    trait :with_state_draft do
      state "draft"
    end

    trait :with_created_by do
      association :created_by, factory: :user, strategy: :build
    end

    trait :with_processed_by do
      association :processed_by, factory: :user, strategy: :build
    end
  end
end
