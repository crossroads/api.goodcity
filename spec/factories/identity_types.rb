# frozen_String_literal: true

FactoryBot.define do
  factory :identity_type do
    sequence(:identifier) { |n| "Identity Type #{n}" }
    name_en               { identifier }
    name_zh_tw            { identifier }
  end
end
