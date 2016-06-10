class CreateStockitLocalOrders < ActiveRecord::Migration
  def change
    create_table :stockit_local_orders do |t|
      t.string :client_name
      t.string :hkid_number
      t.string :reference_number
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
