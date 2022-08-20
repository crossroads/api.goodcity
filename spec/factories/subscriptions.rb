# frozen_String_literal: true

FactoryBot.define do
  factory :subscription, aliases: [:offer_subscription] do
    state { 'unread' }
    message
    user

    trait :with_order do
      message_id { create(:message, messageable: create(:order)).id }
      after(:create) do |subs|
        subs.subscribable = subs.message.messageable
      end
    end

    trait :with_offer do
      message_id  { create(:message, messageable: create(:offer)).id }
      after(:create) do |subs|
        subs.subscribable = subs.message.messageable
      end
    end
  end

  factory :order_subscription, class: :Subscription do
    state    { 'unread' }
    user
    message  { association :message, :with_order }
    trait :with_order do
      association :subscribable, factory: :order
    end
  end
end
