FactoryGirl.define do
  factory :crossroads_transport do
    name_en    { generate(:crossroads_transports).keys.sample }
    name_zh_tw { generate(:crossroads_transports)[name_en][:name_zh_tw] }
    cost       { generate(:crossroads_transports)[name_en][:cost] }
    truck_size { generate(:crossroads_transports)[name_en][:truck_size] }
    initialize_with { CrossroadsTransport.find_or_initialize_by(name_en: name_en) }
  end
end
