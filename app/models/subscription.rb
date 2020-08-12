class Subscription < ApplicationRecord
  include PushUpdatesForSubscription
  belongs_to :user
  belongs_to :message

  belongs_to :subscribable, polymorphic: true

  after_create :send_new_message_notification # PushUpdatesForSubscription

  scope :unread, -> { where(state: 'unread') }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
end
