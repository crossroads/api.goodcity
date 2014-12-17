class CreateTimeslots < ActiveRecord::Migration
  def change
    create_table :timeslots do |t|
      t.string :name_en
      t.string :name_zh_tw

      t.timestamps
    end
  end
end
