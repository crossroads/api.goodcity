class RemoveRecipientIdFromMessage < ActiveRecord::Migration[4.2]
  def change
    remove_column :messages, :recipient_id
  end
end
