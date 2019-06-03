#rake goodcity:update_sms_reminder_sent_at
namespace :goodcity do
  desc 'Set all User.sms_reminder_sent_at values to now'
  task update_sms_reminder_sent_at: :environment do
    User.update_all(sms_reminder_sent_at: Time.now)
  end
end
