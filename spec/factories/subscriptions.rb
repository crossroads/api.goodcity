# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :subscription, aliases: [:offer_subscription] do
    user_id     { create(:user).id }
    message_id  { create(:message).id }
    state 'unread'
    trait :with_offer do
      association :subscribable, factory: :offer
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
