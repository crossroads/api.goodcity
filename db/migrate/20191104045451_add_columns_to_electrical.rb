class AddColumnsToElectrical < ActiveRecord::Migration
  def change
    add_column :electricals, :test_status_id, :integer
    add_column :electricals, :voltage_id, :integer
    add_column :electricals, :frequency_id, :integer
  end
end
