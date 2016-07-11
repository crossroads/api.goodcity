class AddStockitMoveColumnsToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :stockit_moved_on, :date
    add_column :packages, :stockit_moved_by_id, :integer
  end
end
