class AddIndexesToUser < ActiveRecord::Migration
  def change
    add_index :users, :sms_reminder_sent_at
  end
end
