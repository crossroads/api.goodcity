# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :rejection_reason do
    name_en         { generate(:rejection_reasons).keys.sample }
    name_zh_tw      { generate(:rejection_reasons)[name_en][:name_zh_tw] }
    initialize_with { RejectionReason.find_or_initialize_by(name_en: name_en) }
  end
end
