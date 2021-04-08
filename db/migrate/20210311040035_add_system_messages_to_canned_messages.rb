class AddSystemMessagesToCannedMessages < ActiveRecord::Migration[6.1]
  def change
    add_column :canned_responses, :message_type, :string, default: 'USER'
    add_column :canned_responses, :guid, :string
  end
end
