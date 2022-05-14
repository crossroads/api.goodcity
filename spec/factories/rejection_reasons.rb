FactoryBot.define do
  factory :rejection_reason do
    sequence(:name_en) { |n| "Rejection Reason #{n}" }
    name_zh_tw         { name_en }
  end
end
