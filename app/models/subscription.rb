class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  belongs_to :offer
  belongs_to :order, inverse_of: :subscriptions

  scope :unread, -> { where(state: 'unread') }
end
