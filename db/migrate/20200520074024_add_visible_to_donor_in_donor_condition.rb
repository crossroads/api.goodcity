class AddVisibleToDonorInDonorCondition < ActiveRecord::Migration
  def change
    add_column :donor_conditions, :visible_to_donor, :boolean, default: true, null: false
  end
end
