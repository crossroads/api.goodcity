class AddDispatchStartedByToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :dispatch_started_by, :integer
  end
end
