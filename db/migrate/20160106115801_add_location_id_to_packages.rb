class AddLocationIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :location_id, :integer
  end
end
