class AddDistrictOfficial < ActiveRecord::Migration[6.1]
  def change
    create_table :districts_official do |t|
      t.string :name
      t.string :name_zh_tw
      t.timestamps
    end
    add_reference :districts, :districts_official
  end
end
