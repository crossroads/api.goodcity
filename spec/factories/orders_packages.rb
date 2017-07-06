FactoryGirl.define do
  factory :orders_package do
    association  :order
    association  :package
    association :updated_by, factory: :user, strategy: :build
    state         ["requested", "cancelled", "designated", "received", "dispatched"].sample
    quantity      2

    trait :with_state_requested do
      state "requested"
    end

    trait :with_state_designated do
      state "designated"
    end
  end

  trait :with_state_requested do
    state 'requested'
  end

  trait :with_state_cancelled do
    state 'cancelled'
  end
end
