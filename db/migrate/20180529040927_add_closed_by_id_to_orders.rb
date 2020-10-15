class AddClosedByIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :closed_by_id, :integer
  end
end
