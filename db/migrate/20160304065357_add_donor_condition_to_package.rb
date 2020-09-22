class AddDonorConditionToPackage < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :donor_condition_id, :integer
    add_column :packages, :grade, :string
  end
end
