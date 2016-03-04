class AddDonorConditionToPackage < ActiveRecord::Migration
  def change
    add_column :packages, :donor_condition_id, :integer
    add_column :packages, :grade, :string
  end
end
