# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :message do
    body        { Faker::Lorem.paragraph }
    sender      { |m| m.association(:user) }
    is_private  false
    state       { "unread" }
    offer
    item

    trait :reviewer_message do
      sender   { |m| m.association(:user, :reviewer) }
    end

    trait :supervisor_message do
      sender   { |m| m.association(:user, :supervisor) }
    end

    trait :subscribe_to_message do
      ignore do
        offer_subscription_count 1
      end
      after(:create) do |message, evaluator|
        create_list(:offer_subscription, evaluator.offer_subscription_count, message: message)
      end
    end
  end

end
