class CreateHolidays < ActiveRecord::Migration[4.2]
  def change
    create_table :holidays do |t|
      t.datetime :holiday
      t.integer :year
      t.string :name

      t.timestamps
    end
  end
end
