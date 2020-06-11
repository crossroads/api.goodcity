class AddRestrictionIdToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :restriction_id, :integer
  end
end
