# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    cloudinary_id { Faker::Lorem.characters(10) }
    favourite false
    association :item

    factory :favourite_image do
      favourite true
    end
  end
end
