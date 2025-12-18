class AddIconUrlToPackageCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :package_categories, :icon_url, :string
  end
end
