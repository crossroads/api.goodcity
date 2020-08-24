class Temp < ActiveRecord::Migration
  def change
    add_column :users, :printer_id, :int
  end
end
