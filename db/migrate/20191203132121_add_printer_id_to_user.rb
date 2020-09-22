class AddPrinterIdToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :printer_id, :integer
  end
end
