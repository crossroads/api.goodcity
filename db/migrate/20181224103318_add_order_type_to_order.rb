class AddOrderTypeToOrder < ActiveRecord::Migration
  def change
    add_column :orders, :order_type, :string
  end
end
