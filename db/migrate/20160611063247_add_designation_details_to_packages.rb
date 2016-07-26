class AddDesignationDetailsToPackages < ActiveRecord::Migration
  def change
    add_column :packages, :stockit_designated_on, :date
    add_column :packages, :stockit_designated_by_id, :integer
  end
end
