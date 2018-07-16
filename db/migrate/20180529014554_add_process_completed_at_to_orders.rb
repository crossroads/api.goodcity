class AddProcessCompletedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :process_completed_at, :datetime
  end
end
