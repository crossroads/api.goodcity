class ChangeOfferIdConstraintOnPackages < ActiveRecord::Migration[4.2]
  def up
    change_column :packages, :offer_id, :integer, :null => true, :default => 0
  end

  def down
    change_column :packages, :offer_id, :integer, :null => false, :default => 0
  end
end
