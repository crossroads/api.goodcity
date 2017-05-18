class AddPackagesStockitIdIndex < ActiveRecord::Migration
  def change
    add_index :packages, :stockit_id
  end
end
