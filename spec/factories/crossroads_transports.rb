FactoryBot.define do
  factory :crossroads_transport do
    sequence(:name_en) { |n| generate(:crossroads_transports).keys.sort[n%generate(:crossroads_transports).keys.size] }
    name_zh_tw { generate(:crossroads_transports)[name_en][:name_zh_tw] }
    cost       { generate(:crossroads_transports)[name_en][:cost] }
    truck_size { generate(:crossroads_transports)[name_en][:truck_size] }
    initialize_with { CrossroadsTransport.find_or_initialize_by(name_en: name_en) }
  end
end
