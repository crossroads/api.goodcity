class CreatePackageSubCategories < ActiveRecord::Migration[4.2]
  def change
    create_table :package_sub_categories do |t|
      t.integer :package_type_id
      t.integer :package_category_id

      t.timestamps null: false
    end
  end
end
