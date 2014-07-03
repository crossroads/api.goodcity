class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.integer :order
      t.string :image
      t.boolean :favourite
      t.string :parent_type
      t.integer :parent_id

      t.timestamps
    end
  end
end
