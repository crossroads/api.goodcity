FactoryGirl.define do
  factory :stockit_local_order do
    client_name {FFaker::Name.first_name}
    hkid_number "MyString"
    reference_number "MyString"
    stockit_id 1
  end
end
