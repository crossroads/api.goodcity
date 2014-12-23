FactoryGirl.define do
  factory :crossroads_transport do
    name_en    { generate(:crossroads_transports)[:name_en] }
    name_zh_tw { generate(:crossroads_transports)[:name_zh_tw] }
    initialize_with { CrossroadsTransport.new(name_en: name_en) }
  end
end
