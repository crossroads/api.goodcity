FactoryBot.define do
  factory :crossroads_transport do
    sequence(:name_en) { |n| "Crossroads Transport #{n}" }
    name_zh_tw         { name_en }
    cost               { rand(1000) }
    truck_size         { rand.truncate(2) }
    is_van_allowed     { true }
  end
end
