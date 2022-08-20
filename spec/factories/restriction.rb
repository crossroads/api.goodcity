FactoryBot.define do
  factory :restriction do
    sequence(:name_en) { |n| "Restriction #{n}" }
    name_zh_tw         { name_en }
  end
end
