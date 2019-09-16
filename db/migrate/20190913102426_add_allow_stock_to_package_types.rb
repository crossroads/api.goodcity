class AddAllowStockToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :allow_stock, :boolean, default: false
  end
end
