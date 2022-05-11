FactoryBot.define do
  factory :gogovan_transport do
  sequence(:name_en) { |n| generate(:gogovan_transports).keys.sort[n%generate(:gogovan_transports).keys.size] }
  name_zh_tw         { generate(:gogovan_transports)[name_en][:name_zh_tw] }
  disabled           { generate(:gogovan_transports)[name_en][:disabled] }
  initialize_with    { GogovanTransport.find_or_initialize_by(name_en: name_en) }
  end
end
