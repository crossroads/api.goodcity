class RenamePackageSubCategoriesAndAddIndexes < ActiveRecord::Migration
  def change
    add_index :package_categories, :parent_id

    rename_table :package_sub_categories, :package_categories_package_types
    add_index :package_categories_package_types, :package_type_id
    add_index :package_categories_package_types, :package_category_id
  end
end
