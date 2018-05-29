class AddCancelledByIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :cancelled_by_id, :integer
  end
end
