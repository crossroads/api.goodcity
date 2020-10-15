class AddDispatchStartedByToOrders < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :dispatch_started_by, :integer
  end
end
