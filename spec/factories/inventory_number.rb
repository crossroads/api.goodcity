FactoryGirl.define do
  factory :inventory_number do
    code { rand(100000..999999) }
  end
end
