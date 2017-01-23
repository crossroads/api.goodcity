# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :offer do
    language       "en"
    state          "draft"
    origin         "web"
    stairs         { [false, true].sample }
    parking        { [false, true].sample }
    estimated_size { [1,2,3,4].sample.to_s }
    notes          { FFaker::Lorem.paragraph }
    created_by     {|m| m.association(:user) }
    reviewed_by_id nil
    reviewed_at    nil
    received_at    nil
    review_completed_at nil

    trait :submitted do
      submitted_at { Time.now }
      state        'submitted'
    end

    trait :received do
      state "received"
      received_at { Time.now }
    end

    trait :closed do
      reviewed_at { Time.now }
      state "closed"
    end

    trait :cancelled do
      cancelled_at { Time.now }
      state "cancelled"
    end

    trait :reviewed do
      reviewed_at { Time.now }
      state       'reviewed'
      association :reviewed_by, factory: :user
      review_completed_at { Time.now }
    end

    trait :under_review do
      reviewed_at { Time.now }
      state       'under_review'
      association :reviewed_by, factory: :user
    end

    trait :scheduled do
      state 'scheduled'
    end

    trait :with_items do
      transient do
        items_count 1
      end
      after(:create) do |offer, evaluator|
        evaluator.items_count.times { create :item, :with_packages, :with_images, offer: offer }
      end
    end

    trait :with_messages do
      transient do
        messages_count 1
      end
      after(:create) do |offer, evaluator|
        create_list(:message, evaluator.messages_count, sender: offer.created_by, offer: offer)
      end
    end

    trait :with_messages_body do
      message=["Thank you for this", "What an excellent thing.", "Thanks for your reply", "We thank you for choosing to donate.", "The item is in good condition"].sample
      transient do
        messages_count 1
      end

      after(:create) do |offer, evaluator|
        create_list(:message, evaluator.messages_count, body: message ,sender: offer.created_by, offer: offer)
      end

    end


    trait :paranoid do
      state      "submitted"
      items      { [create(:item)] }
    end

    trait :with_transport do
      association    :gogovan_transport
      association    :crossroads_transport
    end
  end

end
