class AddQuantityToRequestedPackages < ActiveRecord::Migration
  def change
    add_column :requested_packages, :quantity, :integer, default: 1
  end
end
