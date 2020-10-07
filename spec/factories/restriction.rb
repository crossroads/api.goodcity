FactoryBot.define do
  factory :restriction do
    name_en { FFaker::Lorem.word }
    name_zh_tw { FFaker::Lorem.word }
  end
end
