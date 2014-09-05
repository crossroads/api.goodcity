class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.string :resource
      t.integer :slot
      t.string :slot_name
      t.string :zone
      t.datetime :scheduled_at

      t.timestamps
    end
  end
end
