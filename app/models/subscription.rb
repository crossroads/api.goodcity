class Subscription < ActiveRecord::Base
  include PushUpdatesForSubscription
  belongs_to :user
  belongs_to :message
  belongs_to :offer
  belongs_to :order, inverse_of: :subscriptions

  after_create :send_new_message_notification # PushUpdatesForSubscription

  scope :unread, -> { where(state: 'unread') }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
end
