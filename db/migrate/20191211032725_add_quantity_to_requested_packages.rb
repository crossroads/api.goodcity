class AddQuantityToRequestedPackages < ActiveRecord::Migration[4.2]
  def change
    add_column :requested_packages, :quantity, :integer, default: 1
  end
end
