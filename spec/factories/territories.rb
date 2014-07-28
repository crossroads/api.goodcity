# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :territory do
    name_en         { generate(:territories).keys.sample }
    name_zh_tw      { generate(:territories)[name_en][:name_zh_tw] }
    initialize_with { Territory.find_or_initialize_by(name_en: name_en) }
  end
end
