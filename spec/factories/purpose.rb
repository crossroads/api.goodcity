FactoryBot.define do
  factory :purpose do
    name_en { FFaker::Lorem.word }
    name_zh_tw { FFaker::Lorem.word }
    identifier { FFaker::Lorem.word }
  end
end
