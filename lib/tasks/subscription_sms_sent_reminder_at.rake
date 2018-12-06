require "goodcity/rake_logger"

namespace :goodcity do
  desc 'Update sms_reminder_sent_at to next day'

  task update_sms_reminder_sent_at: :environment do
    log = Goodcity::RakeLogger.new("update_sms_reminder_sent_at")
    success_count = 0

    nil_sms_reminder_count = Subscription.where(sms_reminder_sent_at: nil).count
    log.info("\nSubscription with nil value: #{nil_sms_reminder_count}")

    Subscription.find_each(batch_size: 100) do |subscription|
      success_count +=1 if subscription.update_column(:sms_reminder_sent_at, Time.zone.now + 24.hours)
    end

    log.info("\nTotal Records Updated: #{success_count}")
  end
end
