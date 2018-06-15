class AddProcessCompletedByIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :process_completed_by_id, :integer
  end
end
