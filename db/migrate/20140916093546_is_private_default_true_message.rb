class IsPrivateDefaultTrueMessage < ActiveRecord::Migration[4.2]
  def change
    change_column_default :messages, :is_private, false
    remove_column :messages, :recipient_type
  end
end
