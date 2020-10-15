class AddInventoryNumberToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :inventory_number, :string
  end
end
