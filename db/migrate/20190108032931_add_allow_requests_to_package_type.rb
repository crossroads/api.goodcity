class AddAllowRequestsToPackageType < ActiveRecord::Migration
  def change
    add_column :package_types, :allow_requests, :boolean, :default => true
  end
end
