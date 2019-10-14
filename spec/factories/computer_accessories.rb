FactoryBot.define do
  factory :computer_accessory do
    brand  "HP"
    country_id "234"
    size "22\""
    interface "DisplayPort/DVI/VGA/USB"
    comp_voltage "110-220V"
    comp_test_status "ACTIVE"
  end
end
