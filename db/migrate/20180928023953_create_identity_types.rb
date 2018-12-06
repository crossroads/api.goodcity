class CreateIdentityTypes < ActiveRecord::Migration
  def change
    create_table :identity_types do |t|
      t.string :identifier
      t.string :name_en
      t.string :name_zh_tw
      t.timestamps null: false
    end
  end
end
