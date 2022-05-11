# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :donor_condition do
    sequence(:name_en) { |n| generate(:donor_conditions).keys.sort[n%generate(:donor_conditions).keys.size] }
    name_zh_tw         { generate(:donor_conditions)[name_en][:name_zh_tw] }
    visible_to_donor   { generate(:donor_conditions)[name_en][:visible_to_donor] }
    initialize_with    { DonorCondition.find_or_initialize_by(name_en: name_en) }
  end
end
