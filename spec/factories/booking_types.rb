FactoryBot.define do
  factory :booking_type do
    identifier "online-order"
    name_en "online order"
    name_zh_tw "online order"

    initialize_with {
      BookingType.find_or_initialize_by(identifier: identifier)
    }
  end
end