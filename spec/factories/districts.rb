# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :district do
    sequence(:name_en) { |n| generate(:districts).keys.sort[n%generate(:districts).keys.size] }
    name_zh_tw         { generate(:districts)[name_en][:name_zh_tw] }
    territory          { create(:territory, name_en: generate(:districts)[name_en][:territory_name_en]) }
    initialize_with    { District.find_or_initialize_by(name_en: name_en) }
    latitude           { 22.5029632 }
    longitude          { 114.1277213 }
  end
end
