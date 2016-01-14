FactoryGirl.define do
  factory :cancellation_reason do
    name_en         { generate(:cancellation_reasons).keys.sample }
    name_zh_tw      { generate(:cancellation_reasons)[name_en][:name_zh_tw] }
    initialize_with { CancellationReason.find_or_initialize_by(name_en: name_en) }
  end
end

