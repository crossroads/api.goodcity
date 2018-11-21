require "goodcity/rake_logger"

namespace :goodcity do
  desc 'Send SMS for unread messages to User'

  task send_unread_message_reminders: :environment do
    SubscriptionsReminder.new.generate
  end
end
