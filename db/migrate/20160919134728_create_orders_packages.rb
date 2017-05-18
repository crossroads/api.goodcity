class CreateOrdersPackages < ActiveRecord::Migration
  def change
    create_table :orders_packages do |t|
      t.integer :package_id
      t.integer :order_id
      t.string  :state
      t.integer :quantity
      t.integer :reviewed_by_id

      t.timestamps null: false
    end
  end
end
