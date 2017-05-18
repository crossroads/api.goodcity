class AddIndexesOnPackagesLocation < ActiveRecord::Migration
  def change
    add_index :packages_locations, :package_id
    add_index :packages_locations, :location_id
    add_index :packages_locations, [:location_id, :package_id]
  end
end
