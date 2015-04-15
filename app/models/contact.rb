class Contact < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery, inverse_of: :contact

  accepts_nested_attributes_for :address

  private

  #required by PusherUpdates module
  def offer
    delivery.try(:offer)
  end
end
