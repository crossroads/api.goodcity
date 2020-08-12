class CreateAppointmentSlotPresets < ActiveRecord::Migration[4.2]
  def change
    create_table :appointment_slot_presets do |t|
      t.integer :day
      t.integer :hours
      t.integer :minutes
      t.integer :quota
    end
  end
end
