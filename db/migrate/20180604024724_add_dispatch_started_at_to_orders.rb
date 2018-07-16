class AddDispatchStartedAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :dispatch_started_at, :datetime
  end
end
