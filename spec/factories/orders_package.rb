FactoryGirl.define do
  factory :orders_package do
    association  :order
    association  :package
    state         'requested'
    quantity      Random.rand(5)
  end
end
