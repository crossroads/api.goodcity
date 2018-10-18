class AddAddressToOrders < ActiveRecord::Migration
  def change
    add_reference :orders, :address, :default => nil
  end
end
