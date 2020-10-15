class RenameStockitDesignationsToOrders < ActiveRecord::Migration[4.2]
  def change
    rename_table :stockit_designations, :orders
  end
end
