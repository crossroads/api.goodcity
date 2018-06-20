class AddSubmittedByIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :submitted_by_id, :integer
  end
end
