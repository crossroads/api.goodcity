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

    messages       { create_list(:offer_message, (rand(10)+1), sender_id: created_by_id, recipient_id: id) }
    items          { [create(:item)] }

    trait :with_items do
      ignore do
        items_count 1
      end
      after(:create) do |offer, evaluator|
        create_list(:item, evaluator.items_count, offer: offer)
      end
    end

    trait :with_messages do
      ignore do
        messages_count 1
      end
      after(:create) do |offer, evaluator|
        create_list(:message, evaluator.messages_count, sender: offer.created_by, recipient: offer)
      end
    end

    factory :paranoid_offer do
      state      "submitted"
      items      { [create(:item)] }
    end

  end

end
