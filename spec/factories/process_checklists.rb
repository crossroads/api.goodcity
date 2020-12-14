# frozen_string_literal: true

FactoryBot.define do
  factory :process_checklist do
    booking_type do
      BookingType.first || association(:booking_type)
    end
    text_en { FFaker::Lorem.characters(5) }
    text_zh_tw { FFaker::Lorem.characters(5) }
  end
end
