class AddCodeToInventoryNumbers < ActiveRecord::Migration
  def change
    add_column :inventory_numbers, :code, :string

    InventoryNumber.reset_column_information
    Rake::Task['goodcity:update_code_of_inventory_numbers'].invoke
  end
end
