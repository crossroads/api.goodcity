class AddProcessCompletedByIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :process_completed_by_id, :integer
  end
end
