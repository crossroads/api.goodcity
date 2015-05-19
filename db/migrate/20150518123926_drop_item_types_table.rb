class DropItemTypesTable < ActiveRecord::Migration
  def up
    Rake::Task["goodcity:update_packages"].invoke

    rename_column :items, :item_type_id, :package_type_id

    drop_table :item_types
  end

  def down
    rename_column :items, :package_type_id, :item_type_id

    create_table :item_types do |t|
      t.string  :name_en
      t.string  :name_zh_tw
      t.string  :code
      t.integer :parent_id
      t.boolean :is_item_type_node, null: false, default: false

      t.timestamps
    end
  end
end
