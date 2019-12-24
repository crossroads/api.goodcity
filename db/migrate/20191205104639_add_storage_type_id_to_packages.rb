class AddStorageTypeIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :storage_type_id, :integer
    add_index :packages, :storage_type_id
  end
end
