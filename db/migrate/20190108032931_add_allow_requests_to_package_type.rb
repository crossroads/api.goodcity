class AddAllowRequestsToPackageType < ActiveRecord::Migration[4.2]
  def change
    add_column :package_types, :allow_requests, :boolean, :default => true
  end
end
