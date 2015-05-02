class CreateVersions < ActiveRecord::Migration
  def change
    create_table :versions do |t|
      t.string   :item_type, :null => false
      t.integer  :item_id,   :null => false
      t.string   :event,     :null => false
      t.string   :whodunnit
      t.json :object
      t.json :object_changes
      t.integer :related_id
      t.string :related_type
      t.datetime :created_at
    end
    add_index :versions, [:item_type, :item_id]
    add_index :versions, [:related_id, :related_type]
  end
end
