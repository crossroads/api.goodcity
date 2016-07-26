class UpdateStockitLocalOrdersAndStockitDesignations < ActiveRecord::Migration
  def change
    add_column :stockit_designations, :description, :text
    add_column :stockit_designations, :stockit_activity_id, :integer
    add_column :stockit_local_orders, :purpose_of_goods, :text
  end
end
