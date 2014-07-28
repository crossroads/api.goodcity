class CreateDistricts < ActiveRecord::Migration
  def change
    create_table :districts do |t|
      t.string :name
      t.string :name_zh_tw
      t.integer :territory_id

      t.timestamps
    end
  end
end
