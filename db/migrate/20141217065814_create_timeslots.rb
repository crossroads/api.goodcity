class CreateTimeslots < ActiveRecord::Migration[4.2]
  def change
    create_table :timeslots do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps
    end
  end
end
