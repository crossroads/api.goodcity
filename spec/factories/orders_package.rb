FactoryGirl.define do
  factory :orders_package do
    association     :package, factory: :package
    association     :order, factory: :order
    state           'designated'
    quantity        1
  end
end
