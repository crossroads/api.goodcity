class AddDispatchedQuantityToOrdersPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :orders_packages, :dispatched_quantity, :integer, default: 0

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE orders_packages
            SET dispatched_quantity=quantity
            WHERE state='dispatched'
        SQL
      end
    end
  end
end
