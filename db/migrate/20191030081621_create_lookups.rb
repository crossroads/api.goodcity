class CreateLookups < ActiveRecord::Migration
  def change
    create_table :lookups do |t|
      t.string :name
      t.string :value
      t.string :label_en
      t.string :label_zh_tw

      t.timestamps null: false
    end

    add_index :lookups, :name
    add_index :lookups, [:name, :label_en]
    add_index :lookups, [:name, :label_zh_tw]
  end
end
