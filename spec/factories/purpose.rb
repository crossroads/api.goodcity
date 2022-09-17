FactoryBot.define do
  factory :purpose do
    sequence(:name_en)    { |n| "Purpose #{n}" }
    name_zh_tw            { name_en }
    sequence(:identifier) { |n| "Identifier #{n}" }
  end
end
