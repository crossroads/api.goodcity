class AddLocationIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :location_id, :integer
  end
end
