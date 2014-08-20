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

    trait :with_items do
      ignore do
        items_count 1
      end
      after(:create) do |offer, evaluator|
        evaluator.items_count.times { create :item, :with_packages, :with_images, offer: offer }
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
