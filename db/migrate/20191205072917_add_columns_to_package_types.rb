class AddColumnsToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :allow_box, :boolean, default: false
    add_column :package_types, :allow_pallet, :boolean, default: false
  end
end
