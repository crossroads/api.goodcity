class AddSmsReminderSentAtToSubscriptions < ActiveRecord::Migration[4.2]
  def change
    add_column :subscriptions, :sms_reminder_sent_at, :datetime
  end
end
