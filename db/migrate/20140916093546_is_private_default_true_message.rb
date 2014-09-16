class IsPrivateDefaultTrueMessage < ActiveRecord::Migration
  def change
    change_column_default :messages, :is_private, false
    remove_column :messages, :recipient_type
  end
end
