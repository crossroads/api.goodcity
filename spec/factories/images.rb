# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :image do
    cloudinary_id { FactoryGirl.generate(:fake_cloudinary_image_id) }
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
      1416897663/szfmfbmjeq6aphyfflmg.jpg
      1416902230/mmguhm3zdkonc2nynjue.jpg
      1416229451/jgpyo4oxrnfnjriofdjd.jpg
      1416817641/auyhxsvppoohnubhtdvp.jpg
      1416375331/zppxdm5fljlyv3tcfo3p.jpg
      1415435713/i6lzfri9xpjzzznxgfnv.jpg
      1415379081/hbqmdhzk47524ppxw7xs.jpg
      1415015815/iijhzfxwjrkavecs8wjp.jpg
      1414914035/ijip6ea6kjy6zn4mz81q.jpg
      1414308170/kdc3pkmli7du4wcnyppz.jpg
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
