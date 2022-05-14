# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :district do
    sequence(:name_en) { |n| "District #{n}" }
    name_zh_tw         { name_en }
    latitude           { FFaker::Geolocation.lat }
    longitude          { FFaker::Geolocation.lng }
    territory
  end
end
