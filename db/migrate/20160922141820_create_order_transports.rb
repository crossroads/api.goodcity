class CreateOrderTransports < ActiveRecord::Migration
  def change
    create_table :order_transports do |t|
      t.date :scheduled_at
      t.string :timeslot
      t.string :transport_type
      t.string :vehicle_type
      t.integer :contact_id
      t.integer :gogovan_order_id
      t.integer :order_id

      t.timestamps null: false
    end
  end
end
