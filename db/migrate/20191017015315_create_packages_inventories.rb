class CreatePackagesInventories < ActiveRecord::Migration
  def up
    create_table :packages_inventories do |t|
      t.references  :package,       null: false, index: true
      t.references  :location,      null: false, index: true
      t.references  :user,          null: false, index: true
      t.string      :action,        null: false, index: true
      t.string      :source_type,   null: true,  index: true
      t.integer     :source_id,     null: true,  index: true
      t.integer     :quantity,      null: false

      t.timestamps
    end

    add_index :packages_inventories, [:source_type, :source_id]
    add_index :packages_inventories, [:source_id, :source_type]
    add_index :packages_inventories, [:package_id, :source_type]
    add_index :packages_inventories, [:source_type, :package_id]

    add_foreign_key :packages_inventories, :packages
    add_foreign_key :packages_inventories, :locations
    add_foreign_key :packages_inventories, :users
  end

  def down
    drop_table :packages_inventories
  end
end
