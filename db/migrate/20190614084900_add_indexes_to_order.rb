class AddIndexesToOrder < ActiveRecord::Migration[4.2]
  def change
    add_index :orders, :state
    add_index :order_transports, :scheduled_at
    add_index :orders_packages, [:package_id, :order_id]
  end
end
