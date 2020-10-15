class RenameRequestsToGoodcityRequests < ActiveRecord::Migration[4.2]
  def change
    rename_table :requests, :goodcity_requests
  end
end
