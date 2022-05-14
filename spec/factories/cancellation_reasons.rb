# frozen_String_literal: true

FactoryBot.define do
  factory :cancellation_reason do
    sequence(:name_en) { |n| "Cancellation Reason #{n}" }
    name_zh_tw         { name_en }
    visible_to_offer   { true }

    trait :visible_to_offer do
      visible_to_offer { true }
    end

    trait :visible_to_order do
      visible_to_order { true }
    end

    trait :invisible do
      name_en { 'Unwanted' }
      visible_to_offer { false }
    end

    trait :no_show do
      name_en { 'No show' }
    end

  end
end
