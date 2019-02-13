class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :message
  belongs_to :offer

  scope :unread, -> { where(state: 'unread') }

end
