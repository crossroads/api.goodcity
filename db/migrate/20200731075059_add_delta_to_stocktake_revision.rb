class AddDeltaToStocktakeRevision < ActiveRecord::Migration
  def change
    add_column :stocktake_revisions, :processed_delta, :integer, default: 0
  end
end
