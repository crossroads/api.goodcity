# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do

  factory :message do
    body        { Faker::Lorem.paragraph }
    recipient   { |m| m.association(:user) }
    sender      { |m| m.association(:user) }
    is_private  false
    state       'unread'
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

  factory :message_donor_to_reviewer, parent: :message do
    is_private false
    recipient   { |m| m.association(:user, :reviewer) }
    subscribe_to_message
  end

  factory :message_donor_to_supervisor, parent: :message do
    is_private false
    recipient   { |m| m.association(:user, :supervisor) }
    subscribe_to_message
  end

  factory :message_reviewer_to_donor, parent: :message do
    is_private false
    reviewer_message
    subscribe_to_message
  end

  factory :message_supervisor_to_donor, parent: :message do
    is_private false
    supervisor_message
    subscribe_to_message
  end

  factory :message_reviewer_to_supervisor, parent: :message do
    is_private true
    recipient   { |m| m.association(:supervisor) }
    reviewer_message
    subscribe_to_message
  end

  factory :message_supervisor_to_reviewer, parent: :message do
    is_private true
    recipient   { |m| m.association(:reviewer) }
    supervisor_message
    subscribe_to_message
  end

end

