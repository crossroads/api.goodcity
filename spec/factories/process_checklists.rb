FactoryBot.define do
  factory :process_checklist do

    sequence(:text_en) { |n| "Process Checklist #{n}" }
    text_zh_tw         { text_en }
    booking_type

    trait :online_order do
      booking_type { association :booking_type, :online_order }
    end

    trait :appointment do
      booking_type { association :booking_type, :appointment }
    end

  end

end
