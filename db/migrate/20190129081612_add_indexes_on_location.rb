class AddIndexesOnLocation < ActiveRecord::Migration
  def up
    add_index :locations, :stockit_id
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin;"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "CREATE INDEX index_locations_on_building ON locations USING gin (building gin_trgm_ops)"
    execute "CREATE INDEX index_locations_on_area ON locations USING gin (area gin_trgm_ops)"
  end

  def down
    execute "DROP INDEX index_locations_on_area"
    execute "DROP INDEX index_locations_on_building"
    remove_index :locations, :stockit_id
  end
end
