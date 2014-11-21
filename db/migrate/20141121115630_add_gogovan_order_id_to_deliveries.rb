class AddGogovanOrderIdToDeliveries < ActiveRecord::Migration
  def change
    add_column :deliveries, :gogovan_order_id, :integer
  end
end
