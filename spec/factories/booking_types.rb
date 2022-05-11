# frozen_String_literal: true

FactoryBot.define do
  factory :booking_type do
    identifier   { "online-order" }
    name_zh_tw   { identifier }
    name_en      { identifier }

    trait :online_order do
      identifier  { 'online-order' }
      name_zh_tw  { 'online order' }
      name_en     { 'online order' }
    end

    trait :appointment do
      identifier  { 'appointment' }
      name_zh_tw  { 'appointment' }
      name_en     { 'appointment' }
    end

    initialize_with { BookingType.find_or_initialize_by(identifier: identifier) }
  end
end
