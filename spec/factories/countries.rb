FactoryBot.define do
  factory :country do
    name_en    { FFaker::Address.country }
    name_zh_tw { name_en }
  end
end
