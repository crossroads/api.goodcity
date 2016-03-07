class AddVisibleInSelectsInPackageType < ActiveRecord::Migration
  def up
    add_column :package_types, :visible_in_selects, :boolean, default: false
    add_column :package_types, :stockit_id, :integer

    PackageType.reset_column_information
    PackageType.update_all(visible_in_selects: true)
  end

  def down
    remove_column :package_types, :visible_in_selects
    remove_column :package_types, :stockit_id
  end
end
