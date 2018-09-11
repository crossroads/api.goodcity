# Read about factories at https://github.com/thoughtbot/factory_bot

FactoryBot.define do
  factory :subscription, aliases: [:offer_subscription] do
    offer_id {create(:offer).id }
    user_id  {create(:user).id }
    message_id {create(:message).id }
    state 'unread'
  end
end
