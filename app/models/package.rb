class Package < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  belongs_to :item
  belongs_to :package_type, class_name: 'ItemType', inverse_of: :packages

  validates :package_type_id, :quantity, presence: true

  private

  #required by PusherUpdates module
  def offer
    item.offer
  end
end
