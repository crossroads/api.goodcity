class AddNotesIndexToOffers < ActiveRecord::Migration[4.2]
  def up
    execute "CREATE INDEX offers_notes_search_idx ON offers USING gin (notes gin_trgm_ops);"
  end

  def down
    execute "DROP INDEX offers_notes_search_idx;"
  end
end
