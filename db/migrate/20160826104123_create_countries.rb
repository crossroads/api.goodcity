class CreateCountries < ActiveRecord::Migration
  def change
    create_table :countries do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
