class AddStockitSentByIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :stockit_sent_by_id, :integer
  end
end
