class CreateSubpackageTypes < ActiveRecord::Migration
  def change
    create_table :subpackage_types do |t|
      t.integer :package_type_id
      t.integer :subpackage_type_id
      t.boolean :is_default, default: false

      t.timestamps null: false
    end
  end
end
