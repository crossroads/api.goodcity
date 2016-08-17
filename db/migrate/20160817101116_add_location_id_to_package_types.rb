class AddLocationIdToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :location_id, :integer
  end
end
