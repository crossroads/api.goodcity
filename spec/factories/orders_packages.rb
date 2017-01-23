FactoryGirl.define do

  factory :orders_package do
    association  :order
    association  :package
    association  :district
    reviewed_by nil
  end
end
