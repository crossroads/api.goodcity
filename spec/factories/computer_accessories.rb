FactoryBot.define do
  factory :computer_accessory do
    country
    brand  "HP"
    size "22\""
    interface "DisplayPort/DVI/VGA/USB"
    comp_voltage "110-220V"
    association :comp_test_status, factory: :lookup, strategy: :build
  end
end
