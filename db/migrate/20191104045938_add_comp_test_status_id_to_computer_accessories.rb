class AddCompTestStatusIdToComputerAccessories < ActiveRecord::Migration[4.2]
  def change
    add_column :computer_accessories, :comp_test_status_id, :integer
    remove_column :computer_accessories, :comp_test_status
  end
end
