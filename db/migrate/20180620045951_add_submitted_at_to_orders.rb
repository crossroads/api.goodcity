class AddSubmittedAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :submitted_at, :datetime
  end
end
