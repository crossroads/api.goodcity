class AddAddressToOrders < ActiveRecord::Migration[4.2]
  def change
    add_reference :orders, :address, :default => nil
  end
end
