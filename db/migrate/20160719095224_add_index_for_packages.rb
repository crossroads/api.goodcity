class AddIndexForPackages < ActiveRecord::Migration
  def up
    execute "CREATE EXTENSION IF NOT EXISTS btree_gin;"
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    execute "CREATE INDEX inventory_numbers_search_idx ON packages USING gin (inventory_number gin_trgm_ops);"
  end

  def down
    execute "DROP INDEX inventory_numbers_search_idx;"
    execute "DROP EXTENSION IF EXISTS pg_trgm;"
    execute "DROP EXTENSION IF EXISTS btree_gin;"
  end
end
