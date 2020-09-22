class CreateBoxes < ActiveRecord::Migration[4.2]
  def change
    create_table :boxes do |t|
      t.string  :box_number
      t.string  :description
      t.text    :comments
      t.integer :pallet_id
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
