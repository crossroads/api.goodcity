class CreateGogovanOrders < ActiveRecord::Migration[4.2]
  def change
    create_table :gogovan_orders do |t|
      t.integer :booking_id
      t.string :status

      t.timestamps
    end
  end
end
