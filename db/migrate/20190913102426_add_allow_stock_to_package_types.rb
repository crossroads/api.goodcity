class AddAllowStockToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :allow_stock, :boolean, default: false
  end
end
