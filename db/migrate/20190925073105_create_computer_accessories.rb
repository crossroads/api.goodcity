class CreateComputerAccessories < ActiveRecord::Migration[4.2]
  def change
    create_table :computer_accessories do |t|
      t.string :brand
      t.string :model
      t.string :serial_num
      t.integer :country_id
      t.string :size
      t.string :interface
      t.string :comp_voltage
      t.string :comp_test_status
      t.integer :updated_by_id
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
