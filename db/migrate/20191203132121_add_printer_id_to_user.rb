class AddPrinterIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :printer_id, :integer
  end
end
