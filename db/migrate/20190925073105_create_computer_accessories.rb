class CreateComputerAccessories < ActiveRecord::Migration
  def change
    create_table :computer_accessories do |t|
      t.string :brand
      t.string :model
      t.string :serial_number
      t.integer :country_id
      t.string :size
      t.string :interface
      t.string :comp_voltage
      t.string :comp_test_status
      t.integer :updated_by_id

      t.timestamps null: false
    end
  end
end
