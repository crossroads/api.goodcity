# frozen_string_literal: true

FactoryBot.define do
  factory :canned_response do
    name_en { FFaker::Lorem.sentence }
    name_zh_tw { FFaker::Lorem.sentence }
    content_en { FFaker::Lorem.sentence }
    content_zh_tw { FFaker::Lorem.sentence }
  end
end
