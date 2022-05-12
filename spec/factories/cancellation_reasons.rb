# frozen_String_literal: true

FactoryBot.define do
  factory :cancellation_reason do
    sequence(:name_en) { |n| generate(:cancellation_reasons).keys.sort[n%generate(:cancellation_reasons).keys.size] }
    name_zh_tw         { generate(:cancellation_reasons)[name_en][:name_zh_tw] }
    visible_to_offer   { generate(:cancellation_reasons)[name_en][:visible_to_offer] }

    initialize_with    { CancellationReason.find_or_initialize_by(name_en: name_en) }

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
