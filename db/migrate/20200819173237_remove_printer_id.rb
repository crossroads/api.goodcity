class RemovePrinterId < ActiveRecord::Migration
  def up
    remove_column :users, :printer_id, :integer
  end

  def down
    add_column :users, :printer_id, :integer
  end
end