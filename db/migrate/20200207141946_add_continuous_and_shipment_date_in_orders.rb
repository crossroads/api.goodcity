class AddContinuousAndShipmentDateInOrders < ActiveRecord::Migration
  def change
    add_column :orders, :continuous, :boolean, default: false
    add_column :orders, :shipment_date, :date
    add_index :orders, :shipment_date
  end
end

