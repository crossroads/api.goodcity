class AddStockitColumnsToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :stockit_designation_id, :integer
    add_column :packages, :stockit_sent_on, :date
  end
end
