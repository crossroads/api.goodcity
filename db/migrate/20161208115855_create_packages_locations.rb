class CreatePackagesLocations < ActiveRecord::Migration
  def change
    create_table :packages_locations do |t|
      t.integer :package_id
      t.integer :location_id
      t.integer :quantity

      t.timestamps null: false
    end
  end
end
