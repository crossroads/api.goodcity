class AddClosedAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :closed_at, :datetime
  end
end
