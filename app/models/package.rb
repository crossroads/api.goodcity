class Package < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

  validates :package_type_id, presence: true

  private

  #required by PusherUpdates module
  def donor_user_id
    item.offer.created_by_id
  end
end
