class AddSmsReminderSentAtToSubscriptions < ActiveRecord::Migration
  def change
    add_column :subscriptions, :sms_reminder_sent_at, :datetime
  end
end
