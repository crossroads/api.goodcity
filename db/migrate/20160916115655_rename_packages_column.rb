class RenamePackagesColumn < ActiveRecord::Migration
  def change
    rename_column :packages, :stockit_designation_id, :order_id
  end
end
