# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :delivery do
    offer_id 1
    contact_id 1
    schedule_id 1
    delivery_type "MyString"
    start "2014-09-01 12:30:03"
    finish "2014-09-01 12:30:03"
  end
end
