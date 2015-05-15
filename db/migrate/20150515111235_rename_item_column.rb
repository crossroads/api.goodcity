class RenameItemColumn < ActiveRecord::Migration
  def change
    rename_column :items, :item_type_id, :package_type_id
  end
end
