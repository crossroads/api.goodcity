class AddCountedByIdsToStocktakeRevisions < ActiveRecord::Migration[6.1]
  def change
    add_column :stocktake_revisions, :counted_by_ids, :jsonb, default: []
    add_index :stocktake_revisions, :counted_by_ids
  end
end
