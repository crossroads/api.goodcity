class AddBodyIndexOnMessages < ActiveRecord::Migration
  def up
    execute "CREATE INDEX messages_body_search_idx ON messages USING gin (body gin_trgm_ops);"
  end

  def down
    execute "DROP INDEX messages_body_search_idx;"
  end
end
