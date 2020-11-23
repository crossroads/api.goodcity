class DeleteStockitBasedColumns < ActiveRecord::Migration[5.2]
  def change
    remove_column :computer_accessories, :stockit_id, :integer
    remove_column :computers, :stockit_id, :integer
    remove_column :countries, :stockit_id, :integer
    remove_column :electricals, :stockit_id, :integer
    remove_column :locations, :stockit_id, :integer
    remove_column :medicals, :stockit_id, :integer

    remove_column :orders, :stockit_id, :integer
    remove_column :package_types, :stockit_id, :integer

    remove_column :packages, :stockit_id, :integer
    remove_column :pallets, :stockit_id, :integer
  end
end
