class AddVisibleToDonorInDonorCondition < ActiveRecord::Migration[4.2]
  def change
    add_column :donor_conditions, :visible_to_donor, :boolean, default: true, null: false
  end
end
