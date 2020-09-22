class AddDeltaToStocktakeRevision < ActiveRecord::Migration[4.2]
  def change
    add_column :stocktake_revisions, :processed_delta, :integer, default: 0
  end
end
