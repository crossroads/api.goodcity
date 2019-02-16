class Subscription < ActiveRecord::Base
  include PushUpdatesForSubscription
  belongs_to :user
  belongs_to :message
  belongs_to :offer
  belongs_to :order, inverse_of: :subscriptions

  after_create :subscribe_users_to_message # PushUpdatesForSubscription

  scope :unread, -> { where(state: 'unread') }
end
