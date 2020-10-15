class AddIndexForPackageInventoryNumber < ActiveRecord::Migration[4.2]
  def change
    add_index :packages, :inventory_number
  end
end
