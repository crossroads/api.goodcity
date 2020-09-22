class AddProcessCompletedAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :process_completed_at, :datetime
  end
end
