class AddCompletedAtToGogovanOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :gogovan_orders, :completed_at, :datetime

    GogovanOrder.connection.execute("update gogovan_orders set completed_at=updated_at")
  end
end
