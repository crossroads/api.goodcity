class AddDimensionColumnsToPackageTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :package_types, :length, :integer
    add_column :package_types, :width, :integer
    add_column :package_types, :height, :integer
    add_column :package_types, :department, :string
  end
end
