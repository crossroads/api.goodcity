class CreatePackages < ActiveRecord::Migration
  def change
    create_table :packages do |t|
      t.integer :quantity
      t.integer :length
      t.integer :width
      t.integer :height
      t.text :notes
      t.integer :item_id
      t.string :state
      t.datetime :received_at
      t.datetime :rejected_at
      t.integer :package_type_id

      t.timestamps
    end
  end
end
