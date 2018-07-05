class AddSubmittedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :submitted_at, :datetime
  end
end
