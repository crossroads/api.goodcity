class RemoveOrderTypeColumnFromOrder < ActiveRecord::Migration
  def change
  	remove_column :orders, :order_type
  end
end
