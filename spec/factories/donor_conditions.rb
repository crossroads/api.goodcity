# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :donor_condition do
    name_en         { generate(:donor_conditions).keys.sample }
    name_zh_tw      { generate(:donor_conditions)[name_en][:name_zh_tw] }
    initialize_with { DonorCondition.find_or_initialize_by(name_en: name_en) }
  end
end
