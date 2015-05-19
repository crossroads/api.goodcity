class CreatePackageTypes < ActiveRecord::Migration
  def change
    create_table :package_types do |t|
      t.string :code
      t.string :name_en
      t.string :name_zh_tw
      t.string :other_terms_en
      t.string :other_terms_zh_tw

      t.timestamps null: false
    end
  end
end
