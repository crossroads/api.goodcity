class AddDispatchStartedAtToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :dispatch_started_at, :datetime
  end
end
