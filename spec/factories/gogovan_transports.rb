FactoryBot.define do
  factory :gogovan_transport do
    sequence(:name_en) { |n| "Gogovan Transport #{n}" }
    name_zh_tw         { name_en }
    disabled           { false }
  end
end
