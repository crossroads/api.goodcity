class UpdatePackageTypes < ActiveRecord::Migration[6.1]
  def change
    rename_column :package_types, :allow_stock, :allow_package
  end
end
