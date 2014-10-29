# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :offer do
    language       "en"
    state          "draft"
    origin         "web"
    stairs         { [false, true].sample }
    parking        { [false, true].sample }
    estimated_size { [1,2,3,4].sample.to_s }
    notes          { Faker::Lorem.paragraph }
    created_by     {|m| m.association(:user) }
    reviewed_by_id nil
    reviewed_at    nil

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
        create_list(:message, evaluator.messages_count, sender: offer.created_by, recipient: offer.created_by, offer: offer)
      end
    end

    trait :paranoid do
      state      "submitted"
      items      { [create(:item)] }
    end
  end

end
