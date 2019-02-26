FactoryBot.define do
  factory :process_checklist do
    association :booking_type
    text_en { FFaker::Lorem.characters(5) }
    text_zh_tw { FFaker::Lorem.characters(5) }
  end
end