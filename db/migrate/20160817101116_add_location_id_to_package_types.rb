class AddLocationIdToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :location_id, :integer
  end
end
