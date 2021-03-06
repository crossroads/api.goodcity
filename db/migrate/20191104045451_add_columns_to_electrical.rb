class AddColumnsToElectrical < ActiveRecord::Migration[4.2]
  def change
    add_column :electricals, :test_status_id, :integer
    add_column :electricals, :voltage_id, :integer
    add_column :electricals, :frequency_id, :integer

    remove_column :electricals, :voltage
    remove_column :electricals, :frequency
    remove_column :electricals, :test_status
  end
end
