class RenamePackagesColumn < ActiveRecord::Migration[4.2]
  def change
    rename_column :packages, :stockit_designation_id, :order_id
  end
end
