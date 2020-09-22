class AddPackagesStockitIdIndex < ActiveRecord::Migration[4.2]
  def change
    add_index :packages, :stockit_id
  end
end
