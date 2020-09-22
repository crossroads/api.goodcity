class AddStockitIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :stockit_id, :integer
  end
end
