class AddDriverDetailsToGogovanOrders < ActiveRecord::Migration
  def change
    add_column :gogovan_orders, :price, :float
    add_column :gogovan_orders, :driver_name, :string
    add_column :gogovan_orders, :driver_mobile, :string
    add_column :gogovan_orders, :driver_license, :string
  end
end
