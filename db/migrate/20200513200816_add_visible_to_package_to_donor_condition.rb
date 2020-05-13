class AddVisibleToPackageToDonorCondition < ActiveRecord::Migration
  def change
    add_column :donor_conditions, :visible_to_package, :boolean, default: false
  end
end
