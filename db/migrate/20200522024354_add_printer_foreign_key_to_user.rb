class AddPrinterForeignKeyToUser < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :users, :printers
  end
end
