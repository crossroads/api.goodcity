class CreateElectricals < ActiveRecord::Migration[4.2]
  def change
    create_table :electricals do |t|
      t.string :brand
      t.string :model
      t.string :serial_number
      t.integer :country_id
      t.string :standard
      t.string :voltage
      t.string :frequency
      t.string :power
      t.string :system_or_region
      t.string :test_status
      t.date :tested_on
      t.integer :updated_by_id
      t.integer :stockit_id


      t.timestamps null: false
    end
  end
end
