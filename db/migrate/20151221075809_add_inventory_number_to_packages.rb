class AddInventoryNumberToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :inventory_number, :string
  end
end
