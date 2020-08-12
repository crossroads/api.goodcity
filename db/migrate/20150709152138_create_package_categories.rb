class CreatePackageCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :package_categories do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.integer :parent_id

      t.timestamps null: false
    end
  end
end
