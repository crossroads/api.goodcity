class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.string :building
      t.string :area
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
