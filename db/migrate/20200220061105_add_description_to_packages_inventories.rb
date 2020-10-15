class AddDescriptionToPackagesInventories < ActiveRecord::Migration[4.2]
  def change
    add_column :packages_inventories, :description, :text
  end
end
