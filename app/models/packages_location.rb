class PackagesLocation < ActiveRecord::Base
  belongs_to :location
  belongs_to :package

  has_paper_trail class_name: 'Version'

  validates :quantity,  numericality: { greater_than_or_equal_to: 0 }

  scope :exclude_location, -> (location_id) {
    where.not(location_id: location_id)
  }

  def update_quantity(received_quantity)
    update(quantity: received_quantity)
  end

  def update_referenced_orders_package(orders_package_id)
    update_column(:reference_to_orders_package, orders_package_id)
  end
end
