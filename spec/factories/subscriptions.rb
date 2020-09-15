# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :subscription, aliases: [:offer_subscription] do
    message_id { create(:message).id }
    user_id { create(:user).id }
    state 'unread'
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
    user     { create(:user) }
    message  { create(:message, :with_order) }
    state 'unread'
    trait :with_order do
      association :subscribable, factory: :order
    end
  end
end
