class AddStockitColumnsToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :stockit_designation_id, :integer
    add_column :packages, :stockit_sent_on, :date
  end
end
