class CreateComputers < ActiveRecord::Migration
  def change
    create_table :computers do |t|
      t.string :brand
      t.string :model
      t.string :serial_number
      t.integer :country_id
      t.string :size
      t.string :cpu
      t.string :ram
      t.string :hdd
      t.string :optical
      t.string :video
      t.string :sound
      t.string :lan
      t.string :wireless
      t.string :usb
      t.string :comp_voltage
      t.string :comp_test_status
      t.string :os
      t.string :os_serial_number
      t.string :ms_office_serial_number
      t.string :mar_os_serial_number
      t.string :mar_ms_office_serial_numer
      t.integer :updated_by_id
      t.integer :stockit_id

      t.timestamps null: false
    end
  end
end
