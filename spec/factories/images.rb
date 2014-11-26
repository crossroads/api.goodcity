# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    order 1
    image_id { FactoryGirl.generate(:cloudinary_image_id) }
    favourite false
    association :parent, factory: :item
  end
end
