# frozen_String_literal: true

FactoryBot.define do
  factory :message do
    body        { generate(:message_body) }
    is_private  { false }
    association :sender, factory: :user
    association :messageable, factory: :order

    trait :reviewer_message do
      sender   { association(:user, :reviewer) }
    end

    trait :supervisor_message do
      sender   { association(:user, :supervisor) }
    end

    trait :subscribe_to_message do
      transient do
        offer_subscription_count { 1 }
      end
      after(:create) do |message, evaluator|
        create_list(:offer_subscription, evaluator.offer_subscription_count, message: message)
      end
    end

    trait :with_item do
      association :messageable, factory: :item
    end

    trait :private do
      is_private  { true }
    end

    trait :with_order do
      association :messageable, factory: :order
    end

    trait :with_offer do
      association :messageable, factory: :offer
    end
  end

  sequence :message_body do |n|
    messages = [
      "Thank you for your offer. We will review it shortly.",
      "Thanks for your reply. We can accept your items.",
      "Thank you for choosing to donate to GoodCity.",
      "The item is in good condition. We will accept it.",
      "Let me check with our staff. We will contact you shortly.",
      "We are currently closed for Chinese New Year. Could you arrange transport for after the holiday period?",
      "I'm sorry. This item is too large and we are unlikely to find a recipient who can make use of it.",
      "Can I call you to discuss the details of your offer?",
      "We can accept delivery today if you are able to book a van to arrive before 4pm."
    ].sample
  end
end
