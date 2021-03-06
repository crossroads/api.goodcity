class PackagesLocation < ApplicationRecord
  include LocationOperations
  include PushUpdatesMinimal
  include InventoryLegacySupport
  include Secured

  belongs_to :location
  belongs_to :package

  has_paper_trail versions: { class_name: 'Version' }

  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }
  validates :package, :location, presence: true

  scope :exclude_location, ->(location_id) { where.not(location_id: location_id) }

  scope :get_records_associated_with_package, ->(package_id) { where('package_id = (?)', package_id) }

  scope :with_eager_load, -> { includes(%i[package location]) }

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    chans = [Channel::STOCK_CHANNEL]
    chans << Channel::STAFF_CHANNEL if record.package.item_id # The item_id indicates it was donated via the admin app
    chans
  end
end
