class CreateTerritories < ActiveRecord::Migration
  def change
    create_table :territories do |t|
      t.string :name
      t.string :name_zh_tw

      t.timestamps
    end
  end
end
