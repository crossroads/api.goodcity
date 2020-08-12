class AddInventoryNumber < ActiveRecord::Migration[4.2]
  def change
    create_table :inventory_numbers
  end
end
