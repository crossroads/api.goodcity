class AddIndexesToPackageTypes < ActiveRecord::Migration

  def up
    add_index :package_types, :allow_requests
    add_index :package_types, :stockit_id
    add_index :package_types, :visible_in_selects
    execute "CREATE INDEX package_types_name_en_search_idx ON package_types USING gin (name_en gin_trgm_ops);"
    execute "CREATE INDEX package_types_name_zh_tw_search_idx ON package_types USING gin (name_zh_tw gin_trgm_ops);"
  end

  def down
    execute "DROP INDEX package_types_name_zh_tw_search_idx;"
    execute "DROP INDEX package_types_name_en_search_idx;"
    remove_index :package_types, :visible_in_selects
    remove_index :package_types, :stockit_id
    remove_index :package_types, :allow_requests
  end

end
