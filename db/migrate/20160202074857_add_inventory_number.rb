class AddInventoryNumber < ActiveRecord::Migration
  def change
    create_table :inventory_numbers
  end
end
