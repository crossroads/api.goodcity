class AddDesignationNameToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :designation_name, :string
  end
end
