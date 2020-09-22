class AddOrderTypeToOrder < ActiveRecord::Migration[4.2]
  def change
    add_column :orders, :order_type, :string
  end
end
