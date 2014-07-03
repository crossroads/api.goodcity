# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :offer do
    language       "en"
    state          "draft"
    collection_contact_name { Faker::Name.name }
    collection_contact_phone { Faker::PhoneNumber.phone_number }
    origin         "web"
    stairs         { [false, true].sample }
    parking        { [false, true].sample }
    estimated_size { [1,2,3,4].sample }
    notes          { Faker::Lorem.paragraph }
    created_by_id  { create(:user).id }
    items          { create_list(:item, (rand(5)+1)) }
    messages       { create_list(:offer_message, (rand(10)+1), sender_id: created_by_id, recipient_id: id) }
  end

end
