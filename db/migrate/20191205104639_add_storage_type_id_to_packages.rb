class AddStorageTypeIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :storage_type_id, :integer
    add_index :packages, :storage_type_id
  end
end
