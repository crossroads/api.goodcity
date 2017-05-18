class CreateOrganisations < ActiveRecord::Migration
  def change
    create_table :organisations do |t|
      t.string :name_en
      t.string :name_zh_tw
      t.references :organisation_type, index: true, foreign_key: true
      t.text :description_en
      t.text :description_zh_tw
      t.string :registration
      t.string :website
      t.references :country, index: true, foreign_key: true
      t.references :district, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
