class CreateAppointmentSlots < ActiveRecord::Migration
  def change
    create_table :appointment_slots do |t|
      t.timestamp :timestamp
      t.integer :quota
      t.string :note, :default => ''
    end
  end
end
