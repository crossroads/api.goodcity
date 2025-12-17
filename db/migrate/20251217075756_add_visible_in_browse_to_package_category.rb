class AddVisibleInBrowseToPackageCategory < ActiveRecord::Migration[6.1]
  def change
    add_column :package_categories, :visible_in_browse, :boolean, default: true
  end
end
