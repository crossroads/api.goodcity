class CreateGogovanOrders < ActiveRecord::Migration
  def change
    create_table :gogovan_orders do |t|
      t.integer :booking_id
      t.string :status

      t.timestamps
    end
  end
end
