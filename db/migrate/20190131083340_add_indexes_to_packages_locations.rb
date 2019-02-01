class AddIndexesToPackagesLocations < ActiveRecord::Migration
  def change
    add_index :packages_locations, :reference_to_orders_package
    add_index :packages_locations, [:package_id, :location_id]#, unique: true
    remove_index :packages_locations, column: [:location_id, :package_id], name: 'index_packages_locations_on_location_id_and_package_id'
    add_index :packages_locations, [:location_id, :package_id]#, unique: true
  end
end
