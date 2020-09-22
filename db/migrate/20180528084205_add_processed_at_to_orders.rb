class AddProcessedAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :processed_at, :datetime
  end
end
