class AddShippingNumberToOrdersPackages < ActiveRecord::Migration[5.2]
  def change
    add_column :orders_packages, :shipping_number, :integer
  end
end
