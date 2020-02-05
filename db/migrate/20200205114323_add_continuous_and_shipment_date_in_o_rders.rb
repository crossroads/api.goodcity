class AddContinuousAndShipmentDateInORders < ActiveRecord::Migration
  def change
    add_column :orders, :continuous, :boolean, default: false
    add_column :orders, :shipment_date, :date
  end
end
