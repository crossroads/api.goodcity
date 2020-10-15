class AddGogovanOrderIdToDeliveries < ActiveRecord::Migration[4.2]
  def change
    add_column :deliveries, :gogovan_order_id, :integer
  end
end
