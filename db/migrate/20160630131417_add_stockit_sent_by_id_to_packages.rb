class AddStockitSentByIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :stockit_sent_by_id, :integer
  end
end
