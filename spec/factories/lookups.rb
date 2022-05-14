# frozen_String_literal: true

FactoryBot.define do
  factory :lookup do
    sequence(:name)     { |n| "Lookup #{n}" }
    sequence(:key)      { |n| "Key #{n}" }
    sequence(:label_en) { |n| "Label #{n}" }
    label_zh_tw         { label_en }
  end
end
