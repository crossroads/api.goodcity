class CreatePallets < ActiveRecord::Migration[4.2]
  def change
    create_table :pallets do |t|
      t.string  :pallet_number
      t.string  :description
      t.text    :comments
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
