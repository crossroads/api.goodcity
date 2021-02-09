class CreateTransportOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :transport_orders do |t|
      t.integer  :transport_provider_id
      t.string   :order_uuid
      t.string   :status
      t.datetime :scheduled_at
      t.jsonb    :metadata
      t.integer  :source_id
      t.string   :source_type

      t.timestamps
    end
  end
end
