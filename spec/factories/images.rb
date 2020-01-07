# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :image do
    cloudinary_id { FactoryBot.generate(:fake_cloudinary_image_id) }
    favourite false
    trait :with_item do
      association :imageable, factory: :item
    end
  end

  # Uses real images tagged 'demo' in Cloudinary
  factory :demo_image, parent: :image do
    cloudinary_id { generate(:cloudinary_demo_images).values.map{|x| x[:cloudinary_id]}.sample }
    trait :red_chair do
      cloudinary_id { generate(:cloudinary_demo_images)["red_chair"][:cloudinary_id] }
    end
    trait :pots_and_pans do
      cloudinary_id { generate(:cloudinary_demo_images)["pots_and_pans"][:cloudinary_id] }
    end
    trait :high_chair do
      cloudinary_id { generate(:cloudinary_demo_images)["high_chair"][:cloudinary_id] }
    end
    trait :wooden_chair do
      cloudinary_id { generate(:cloudinary_demo_images)["wooden_chair"][:cloudinary_id] }
    end
    trait :kitchen_sink do
      cloudinary_id { generate(:cloudinary_demo_images)["kitchen_sink"][:cloudinary_id] }
    end
    trait :couch do
      cloudinary_id { generate(:cloudinary_demo_images)["couch"][:cloudinary_id] }
    end
    trait :piano do
      cloudinary_id { generate(:cloudinary_demo_images)["piano"][:cloudinary_id] }
    end
    trait :kiprosh_mug do
      cloudinary_id { generate(:cloudinary_demo_images)["kiprosh_mug"][:cloudinary_id] }
    end
    trait :dining_table_chair_set do
      cloudinary_id { generate(:cloudinary_demo_images)["dining_table_chair_set"][:cloudinary_id] }
    end
    trait :baby_chair do
      cloudinary_id { generate(:cloudinary_demo_images)["baby_chair"][:cloudinary_id] }
    end
    trait :office_chair do
      cloudinary_id { generate(:cloudinary_demo_images)["office_chair"][:cloudinary_id] }
    end
  end

  sequence :fake_cloudinary_image_id do |n|
    seq = %w(
      1544512902/test/b888c7e4fe64284b81a510ed425d07e2.jpg
      1544512919/test/ConstructionDrawing.png
      1544512889/test/construction-lines-drawing.jpg
      1544512857/test/3dd7cb65ea694b5f3953632dbc965fcc--structural-drawing-opt-art.jpg
      1544512847/test/89d5cf10e1335a99da4091de089864f9.jpg
      1544512838/test/main-qimg-ab4027fbfdf6e22127294610115fb34f-c.jpg
      1544512823/test/430226-265-635784416490957418_338x600_thumb.jpg
      1544512817/test/bottle1.jpg
      1544512809/test/object-drawing-22.jpg
      1544512555/test/6205979_f520.jpg
    )
    i = n.modulo(seq.size)
    seq[i]
  end

  # red_chair: 
  #   cloudinary_id: "1487128065/demo/jnsuiph0zz06eeah5ddv.jpg"
  sequence :cloudinary_demo_images do |n|
    @cloudinary_demo_images ||= YAML.load_file("#{Rails.root}/db/cloudinary_demo_images.yml")
  end

end
