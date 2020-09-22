class AddCancelledByIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :cancelled_by_id, :integer
  end
end
