# frozen_String_literal: true

FactoryBot.define do
  factory :territory do
    sequence(:name_en) { |n| "Territory #{n}" }
    name_zh_tw         { name_en }
  end
end
