FactoryBot.define do
  factory :computer do
    country
    brand  "Macbook"
    size "13\""
    cpu "1.2Ghz"
    ram "4GB DDR3"
    hdd "500GB SATA"
    optical "VersionTECH"
    video "Radeon RX 470"
    sound "Bose Companion 2 Series III"
    lan "Ethernet Adapter"
    wireless "Andrew"
    usb "2.0, 3.0"
    comp_voltage "100/240V"
    os "Mac OS High Sierra"
    association :comp_test_status, factory: :lookup, strategy: :build
  end
end
