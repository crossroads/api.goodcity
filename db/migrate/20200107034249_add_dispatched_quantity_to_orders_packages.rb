class AddDispatchedQuantityToOrdersPackages < ActiveRecord::Migration
  def change
    add_column :orders_packages, :dispatched_quantity, :integer, default: 0
  end
end
