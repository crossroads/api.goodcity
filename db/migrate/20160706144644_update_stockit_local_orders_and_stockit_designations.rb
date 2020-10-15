class UpdateStockitLocalOrdersAndStockitDesignations < ActiveRecord::Migration[4.2]
  def change
    add_column :stockit_designations, :description, :text
    add_column :stockit_designations, :stockit_activity_id, :integer
    add_column :stockit_local_orders, :purpose_of_goods, :text
  end
end
