FactoryGirl.define do
  factory :country do
    name_en    ["China","USA", "India","Australia"].sample
    name_zh_tw {name_en}
  end
end
