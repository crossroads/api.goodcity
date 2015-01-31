class Schedule < ActiveRecord::Base
  include PushUpdates

  has_many :deliveries

  #required by PusherUpdates module
  def offer
    deliveries.last.try(:offer)
  end
end
