class AddIndexesToVersions < ActiveRecord::Migration
  def change
    remove_index :versions, column: [:related_id, :related_type], name: 'index_versions_on_related_id_and_related_type'
    add_index :versions, [:related_type, :related_id]
    add_index :versions, :event
    add_index :versions, :created_at
    add_index :versions, :item_type
    add_index :versions, :related_type
    
    reversible do |dir|
      dir.up   { change_column :versions, :object, 'jsonb USING CAST(object AS jsonb)' }
      dir.down { change_column :versions, :object, 'json USING CAST(object AS json)' }
    end

    reversible do |dir|
      dir.up   { change_column :versions, :object_changes, 'jsonb USING CAST(object_changes AS jsonb)' }
      dir.down { change_column :versions, :object_changes, 'json USING CAST(object_changes AS json)' }
    end
    
    add_index :versions, [:created_at, :whodunnit], name: 'partial_index_recent_locations', where: "versions.event IN ('create', 'update') AND (object_changes ? 'location_id')"
  end
end
