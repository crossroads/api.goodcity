class MoveSmsReminderAtToUser < ActiveRecord::Migration[4.2]
  def change
    remove_column :subscriptions, :sms_reminder_sent_at, :datetime
    add_column :users, :sms_reminder_sent_at, :datetime, default: nil
  end
end
