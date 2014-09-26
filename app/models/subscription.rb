class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  belongs_to :offers_subscription, class_name: "Offer"
  scope :subscribed_users, ->(sender_id) {
    where("subscriptions.user_id <> ?", sender_id).group("subscriptions.user_id")
  }
  scope :subscribed_privileged_users, ->(sender_id) {
    joins(:user)
    .where("users.permission_id is not null and subscriptions.user_id <> ?", sender_id)
    .select("subscriptions.user_id").group("subscriptions.user_id")
  }
end
