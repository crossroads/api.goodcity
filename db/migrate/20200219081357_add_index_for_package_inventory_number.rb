class AddIndexForPackageInventoryNumber < ActiveRecord::Migration
  def change
    add_index :packages, :inventory_number
  end
end
