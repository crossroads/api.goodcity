class UpdateOrderTransportsAttributes < ActiveRecord::Migration
  def change
    remove_column :order_transports, :vehicle_type, :string

    add_column :order_transports, :need_english, :boolean, default: false
    add_column :order_transports, :need_cart, :boolean, default: false
    add_column :order_transports, :need_carry, :boolean, default: false
    add_column :order_transports, :need_over_6ft, :boolean, default: false

    add_column :order_transports, :gogovan_transport_id, :integer

    add_column :order_transports, :remove_net, :string
  end
end
