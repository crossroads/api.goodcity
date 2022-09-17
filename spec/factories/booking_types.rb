# frozen_String_literal: true

FactoryBot.define do
  factory :booking_type do
    sequence(:identifier) { |n| "identifier-#{n}" }
    name_zh_tw            { identifier }
    name_en               { identifier }
    initialize_with       { BookingType.find_or_initialize_by(identifier: identifier) } # avoid duplicates with traits below

    trait :online_order do
      identifier  { 'online-order' }
    end

    trait :appointment do
      identifier  { 'appointment' }
    end
  end
end
