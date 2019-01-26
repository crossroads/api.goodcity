class MoveSmsReminderAtToUser < ActiveRecord::Migration
  def change
    remove_column :subscriptions, :sms_reminder_sent_at
    add_column :users, :sms_reminder_sent_at, 'timestamp without time zone', default: nil
  end
end
