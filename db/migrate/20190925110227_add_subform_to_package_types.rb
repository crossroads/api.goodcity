class AddSubformToPackageTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :subform, :string
  end
end
