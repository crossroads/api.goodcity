FactoryBot.define do
  factory :organisation_type do
    sequence(:name_en)     { |n| "Organisation Type #{n}" }
    name_zh_tw             { name_en }
    sequence(:category_en) { |n| "Category #{n}" }
    category_zh_tw         { category_en }
  end
end
