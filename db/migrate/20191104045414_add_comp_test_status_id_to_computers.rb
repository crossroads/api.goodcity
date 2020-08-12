class AddCompTestStatusIdToComputers < ActiveRecord::Migration[4.2]
  def change
    add_column :computers, :comp_test_status_id, :integer
    remove_column :computers, :comp_test_status
  end
end
