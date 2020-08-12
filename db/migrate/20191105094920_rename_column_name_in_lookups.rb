class RenameColumnNameInLookups < ActiveRecord::Migration[4.2]
  def change
    rename_column :lookups, :value, :key
  end
end
