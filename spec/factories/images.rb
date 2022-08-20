# frozen_String_literal: true

FactoryBot.define do
  factory :image do
    cloudinary_id
    favourite     { false }
    angle         { 0 }

    trait :with_item do
      association :imageable, factory: :item
    end

    # Uses real images tagged 'test' in Cloudinary
    #   create :image, :red_chair
    YAML.load_file("#{Rails.root}/db/cloudinary_demo_images.yml").each do |name, values|
      trait "#{name}".to_sym do
        cloudinary_id { values[:cloudinary_id] }
      end
    end
  end

  # e.g. "red_chair" or "kitchen_sink"
  sequence :image_demo_names do |n|
    source = FactoryBot.generate(:cloudinary_demo_images).keys
    source[n%source.size]
  end

  sequence :cloudinary_id do |n|
    source = FactoryBot.generate(:cloudinary_demo_images)
    source[source.keys[n%source.keys.size]][:cloudinary_id]
  end

  sequence :cloudinary_demo_images do |n|
    @cloudinary_demo_images ||= YAML.load_file("#{Rails.root}/db/cloudinary_demo_images.yml")
  end

end
