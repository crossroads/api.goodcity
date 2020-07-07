class CreateStocktakeRevisions < ActiveRecord::Migration
  def change
    create_table :stocktake_revisions do |t|
      t.references  :stocktake, null: false, index: true, foreign_key: true
      t.references  :package,   null: false, index: true, foreign_key: true
      t.integer     :quantity,  null: false, default: 0
      t.string      :state,     null: false, default: 'pending'
      t.boolean     :dirty,     null: false, default: false
      t.string      :warning,   null: true
      t.integer     :created_by_id

      t.timestamps null: false
    end

    add_index :stocktake_revisions, [:stocktake_id, :package_id], unique: true
    add_index :stocktake_revisions, [:package_id, :stocktake_id], unique: true
  end
end
