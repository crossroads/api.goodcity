class CreateHolidays < ActiveRecord::Migration
  def change
    create_table :holidays do |t|
      t.datetime :holiday
      t.integer :year
      t.string :name

      t.timestamps
    end
  end
end
