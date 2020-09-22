class AddRestrictionIdToPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :packages, :restriction_id, :integer
  end
end
