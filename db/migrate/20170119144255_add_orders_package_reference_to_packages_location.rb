class AddOrdersPackageReferenceToPackagesLocation < ActiveRecord::Migration[4.2]
  def change
    add_column :packages_locations, :reference_to_orders_package, :integer
  end
end
