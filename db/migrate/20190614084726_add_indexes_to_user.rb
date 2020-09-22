class AddIndexesToUser < ActiveRecord::Migration[4.2]
  def change
    add_index :users, :sms_reminder_sent_at
  end
end
