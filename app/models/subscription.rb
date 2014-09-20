class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  belongs_to :offers_subscription, class_name: "Offer"

  def subscribe_users_to_offers_messages

  end
end
