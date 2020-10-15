class CreatePackageSets < ActiveRecord::Migration[4.2]
  def change
    create_table :package_sets do |t|
      t.integer :package_type_id
      t.text :description

      t.timestamps null: false
    end

    add_column :packages, :package_set_id, :integer
    remove_column :packages, :set_item_id, :integer

    add_index :package_sets, :package_type_id
    add_index :packages, :package_set_id
  end
end
