class CreateStorageTypes < ActiveRecord::Migration
  def change
    create_table :storage_types do |t|
      t.string :name

      t.timestamps null: false
    end
  end
end
