class AddSubformToPackageTypes < ActiveRecord::Migration
  def change
    add_column :package_types, :subform, :string
  end
end
