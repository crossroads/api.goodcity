class AddSystemMessagesToCannedMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :canned_responses, :is_private, :boolean, default: false
    add_column :canned_responses, :guid, :string
  end
end
