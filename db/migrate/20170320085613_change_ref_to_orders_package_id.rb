class ChangeRefToOrdersPackageId < ActiveRecord::Migration
  def change
    rename_column :packages_locations, :reference_to_orders_package, :orders_package_id
  end
end
