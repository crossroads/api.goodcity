class AddCaseNumberToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :case_number, :string
  end
end
