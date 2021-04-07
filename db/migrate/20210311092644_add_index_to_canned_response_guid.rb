class AddIndexToCannedResponseGuid < ActiveRecord::Migration[6.1]
  def change
    add_index :canned_responses, :guid, unique: true
  end
end
