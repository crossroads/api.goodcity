class CreateStocktakes < ActiveRecord::Migration[4.2]
  def change
    create_table :stocktakes do |t|
      t.string :name, null: false
      t.string :state, default: 'open'
      t.string :comment
      t.integer :created_by_id
      t.references :location, index: true, foreign_key: true, null: false
      t.timestamps null: false
    end

    add_index :stocktakes, :name, unique: true
  end
end
