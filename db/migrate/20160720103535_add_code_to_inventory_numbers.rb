class AddCodeToInventoryNumbers < ActiveRecord::Migration[4.2]
  def change
    add_column :inventory_numbers, :code, :string

    InventoryNumber.reset_column_information
    Rake::Task['goodcity:update_code_of_inventory_numbers'].invoke
  end
end
