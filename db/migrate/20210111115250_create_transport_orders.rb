class CreateTransportOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :transport_orders do |t|
      t.integer :transport_provider_id
      t.string :order_uuid
      t.string :status
      t.datetime :scheduled_at
      t.jsonb :metadata
      t.integer :offer_id

      t.timestamps
    end
  end
end
