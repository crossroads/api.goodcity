class CreateItemTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :item_types do |t|
      t.string :name
      t.string :code
      t.integer :parent_id

      t.timestamps
    end
  end
end
