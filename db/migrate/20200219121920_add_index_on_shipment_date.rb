class AddIndexOnShipmentDate < ActiveRecord::Migration
  def change
    add_index :orders, :shipment_date
  end
end
