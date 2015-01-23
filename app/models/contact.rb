class Contact < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery

  private

  #required by PusherUpdates module
  def offer
    delivery.try(:offer)
  end
end
