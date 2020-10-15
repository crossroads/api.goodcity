class AddCancelledAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :cancelled_at, :datetime
  end
end
