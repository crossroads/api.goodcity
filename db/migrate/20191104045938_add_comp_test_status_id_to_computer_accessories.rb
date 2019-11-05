class AddCompTestStatusIdToComputerAccessories < ActiveRecord::Migration
  def change
    add_column :computer_accessories, :comp_test_status_id, :integer
  end
end
