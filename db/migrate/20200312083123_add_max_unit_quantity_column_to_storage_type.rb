class AddMaxUnitQuantityColumnToStorageType < ActiveRecord::Migration
  def change
    add_column :storage_types, :max_unit_quantity, :integer, default: nil
  end
end
