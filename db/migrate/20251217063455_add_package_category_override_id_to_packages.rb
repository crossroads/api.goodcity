class AddPackageCategoryOverrideIdToPackages < ActiveRecord::Migration[6.1]
  def change
    add_reference :packages, :package_category_override, default: nil, foreign_key: { to_table: :package_categories }
  end
end
