FactoryGirl.define do
  factory :box do
    box_number   "MyString"
    description  "MyString"
    comments     "MyText"
    pallet
    stockit_id   1
  end
end
