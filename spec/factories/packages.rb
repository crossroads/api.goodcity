# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :package do
    quantity    1
    length      { rand(199) + 1 }
    width       { rand(199) + 1 }
    height      { rand(199) + 1 }
    notes       { Faker::Lorem.paragraph }
    state       'draft'
    package_type_id { create(:item_type).id }
    received_at nil
    rejected_at nil
  end
end
