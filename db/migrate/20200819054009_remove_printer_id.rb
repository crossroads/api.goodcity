class RemovePrinterId < ActiveRecord::Migration
  def change
    remove_column :users, :printer_id
  end
end
