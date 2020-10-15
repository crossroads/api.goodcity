class AddSubmittedByIdToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :submitted_by_id, :integer
  end
end
