class AddColumnToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :cancellation_reason, :text
  end
end
