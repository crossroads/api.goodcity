FactoryBot.define do
  factory :booking_type do
    identifier "lorem-ipsum"
    name_en "lorem ipsum"
    name_zh_tw "lorem ipsum"

    initialize_with {
      BookingType.find_or_initialize_by(identifier: identifier)
    }
  end
end