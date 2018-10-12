class RenameRequestsToGoodcityRequests < ActiveRecord::Migration
  def change
    rename_table :requests, :goodcity_requests
  end
end
