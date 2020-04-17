class AddMedicalSubform < ActiveRecord::Migration
  def change
    create_table :medicals do |t|
      t.string :serial_number
      t.string :model
      t.string :brand
      t.integer :country_id
      t.integer :updated_by_id
      t.integer :stockit_id
      t.timestamps null: false
    end
  end
end
