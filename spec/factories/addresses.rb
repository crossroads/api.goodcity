# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :address do
    flat         { Faker::Address.secondary_address }
    building     { Faker::Address.building_number }
    street       { Faker::Address.street_name }
    association  :district
    address_type "Collection"
    addressable_id   { create(:contact).id }
    addressable_type 'Contact'

  end

  factory :profile_address, parent: :address do
    address_type "profile"
    district_id "1"
  end
end
