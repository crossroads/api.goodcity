# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    order 1
    image_id { Faker::Lorem.characters(10) }
    favourite false
    association :parent, factory: :item

    factory :favourite_image do
      favourite true
    end
  end
end
