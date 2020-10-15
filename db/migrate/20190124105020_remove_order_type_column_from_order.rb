class RemoveOrderTypeColumnFromOrder < ActiveRecord::Migration[4.2]
  def change
  	remove_column :orders, :order_type
  end
end
