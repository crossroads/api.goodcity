class CreateOrganisationTypes < ActiveRecord::Migration
  def change
    create_table :organisation_types do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.string :category_en
      t.string :category_zh_tw

      t.timestamps null: false
    end
  end
end
