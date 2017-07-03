class PackagesLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :package

  has_paper_trail class_name: 'Version'

  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }
  validates_with PackageQuantityValidator

  scope :exclude_location, -> (location_id) {
    where.not(location_id: location_id)
  }

  scope :with_eager_load, -> {
     includes([:package, :location])
  }

  def update_quantity(received_quantity)
    update_column(quantity: received_quantity)
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
end
