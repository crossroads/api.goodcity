class RenameStockitDesignationsToOrders < ActiveRecord::Migration
  def change
    rename_table :stockit_designations, :orders
  end
end
