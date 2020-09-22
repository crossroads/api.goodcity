class AddColumnsToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :allow_box, :boolean, default: false
    add_column :package_types, :allow_pallet, :boolean, default: false
  end
end
