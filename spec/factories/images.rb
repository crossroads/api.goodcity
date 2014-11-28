# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    cloudinary_id { FactoryGirl.generate(:cloudinary_image_id) }
    favourite false
    association :item
  end
end
