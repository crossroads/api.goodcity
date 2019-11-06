FactoryBot.define do
  factory :electrical do
    brand  "YAMAHA"
    country
    association :voltage, factory: :lookup, strategy: :build
    association :frequency, factory: :lookup, strategy: :build
    association :test_status, factory: :lookup, strategy: :build
    power "2150"
    system_or_region "AUDIO VISUAL"
  end
end
