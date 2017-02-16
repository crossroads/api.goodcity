FactoryGirl.define do
  factory :orders_package do
    association  :order
    association  :package
    association :updated_by, factory: :user, strategy: :build
    state         ["requested", "cancelled", "designated", "received", "dispatched"].sample
    quantity      Random.rand(5)

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
end
