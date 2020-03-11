class AddDescriptionToPackagesInventories < ActiveRecord::Migration
  def change
    add_column :packages_inventories, :description, :text
  end
end
