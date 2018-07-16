class AddClosedByIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :closed_by_id, :integer
  end
end
