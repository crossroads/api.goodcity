FactoryBot.define do
  factory :booking_type do
    identifier { generate(:booking_types).keys.sample }
    name_en    { generate(:booking_types)[:name_en] }
    name_zh_tw { generate(:booking_types)[:name_zh_tw] }
    initialize_with { BookingType.find_or_initialize_by(identifier: identifier) }
  end
end