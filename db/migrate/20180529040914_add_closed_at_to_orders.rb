class AddClosedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :closed_at, :datetime
  end
end
