class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  belongs_to :offers_subscription, class_name: "Offer"
  scope :subscribed_users, -> (sender_id){
    where("subscriptions.user_id <> ?", sender_id).pluck(:user_id)
  }
end
