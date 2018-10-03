class CreateIdentityTypes < ActiveRecord::Migration
  def change
    create_table :identity_types do |t|
      t.string :name
      t.timestamps null: false
    end
  end
end
