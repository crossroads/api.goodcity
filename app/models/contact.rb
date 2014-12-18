class Contact < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery

  private

  #required by PusherUpdates module
  def donor_user_id
    address.user_id
  end
end
