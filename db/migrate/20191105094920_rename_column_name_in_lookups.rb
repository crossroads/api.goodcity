class RenameColumnNameInLookups < ActiveRecord::Migration
  def change
    rename_column :lookups, :value, :key
  end
end
