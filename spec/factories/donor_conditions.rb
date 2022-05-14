# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :donor_condition do
    name_en            { |n| "Donor condition #{n}" }
    name_zh_tw         { name_en }
    visible_to_donor   { true }
  end
end
