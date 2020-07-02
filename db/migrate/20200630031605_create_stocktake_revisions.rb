class CreateStocktakeRevisions < ActiveRecord::Migration
  def change
    create_table :stocktake_revisions do |t|
      t.references :stocktake, index: true, foreign_key: true, null: false
      t.references :package, index: true, foreign_key: true, null: false
      t.integer :quantity, default: 0
      t.string :state, default: 'pending'
      t.string :warning_en, null: false
      t.string :warning_zh_tw, null: false
      t.boolean :dirty, default: false
      t.timestamps null: false
    end

    add_index :stocktake_revisions, [:stocktake_id, :package_id], unique: true
    add_index :stocktake_revisions, [:package_id, :stocktake_id], unique: true
  end
end
