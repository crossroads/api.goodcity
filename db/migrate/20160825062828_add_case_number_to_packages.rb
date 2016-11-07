class AddCaseNumberToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :case_number, :string
  end
end
