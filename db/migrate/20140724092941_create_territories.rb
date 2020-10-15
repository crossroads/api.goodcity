class CreateTerritories < ActiveRecord::Migration[4.2]
  def change
    create_table :territories do |t|
      t.string :name
      t.string :name_zh_tw

      t.timestamps
    end
  end
end
