# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :district do
    name_en         { generate(:districts).keys.sample }
    name_zh_tw      { generate(:districts)[name_en][:name_zh_tw] }
    territory       { create(:territory, name_en: generate(:districts)[name_en][:territory_name_en]) }
    initialize_with { District.find_or_initialize_by(name_en: name_en) }
    latitude        { 22.5029632 }
    longitude       { 114.1277213 }
  end
end
