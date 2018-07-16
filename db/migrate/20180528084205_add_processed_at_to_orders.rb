class AddProcessedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :processed_at, :datetime
  end
end
