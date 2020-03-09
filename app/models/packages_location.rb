class PackagesLocation < ActiveRecord::Base
  include RollbarSpecification
  include LocationOperations
  include PushUpdatesMinimal
  include InventoryLegacySupport

  belongs_to :location
  belongs_to :package

  has_paper_trail class_name: 'Version'

  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }
  validates :package, :location, presence: true

  scope :exclude_location, ->(location_id) {
    where.not(location_id: location_id)
  }

  scope :get_records_associated_with_package, ->(package_id) { where("package_id = (?)", package_id) }

  scope :with_eager_load, -> {
    includes([:package, :location])
  }

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    chans = [Channel::STOCK_CHANNEL]
    chans << Channel::STAFF_CHANNEL if record.package.item_id # The item_id indicates it was donated via the admin app
    chans
  end

  def update_quantity(received_quantity)
    update(quantity: received_quantity)
  end

  def update_referenced_orders_package(orders_package_id)
    update_column(:reference_to_orders_package, orders_package_id)
  end

  def update_location_quantity_and_reference(location_id, quantity, reference_to_orders_package)
    update(
      location_id: location_id,
      quantity: quantity,
      reference_to_orders_package: reference_to_orders_package
    )
  end

  def self.available_quantity_at_location(location_id, package_id)
    find_by(location_id: location_id, package_id: package_id)&.quantity
  end
end
