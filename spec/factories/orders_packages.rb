FactoryGirl.define do
  factory :orders_package do
    association  :order
    association  :package
    association :reviewed_by, factory: :user, strategy: :build
    state         ["requested", "cancelled", "designated", "received", "dispatched"].sample
    quantity      Random.rand(5)
  end
end
