FactoryBot.define do
  factory :country do
    name_en    ["China","USA", "India","Australia"].sample
    name_zh_tw {name_en}

    trait :with_stockit_id do
      stockit_id { rand(1000) + 1 }
    end
  end
end
