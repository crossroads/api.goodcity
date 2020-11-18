class AddDescriptionToPackageTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :package_types, :description_en, :text
    add_column :package_types, :description_zh_tw, :text
  end
end
