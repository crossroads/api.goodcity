class AddStockitIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :stockit_id, :integer
  end
end
