class AddColumnToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :cancellation_reason, :text
  end
end
