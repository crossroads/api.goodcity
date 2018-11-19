require "goodcity/rake_logger"

namespace :goodcity do
  desc 'Send SMS for unread messages to User'

  task send_unread_messages_sms_to_user: :environment do
    Subscription.where(state: 'unread', user_id: Offer.uniq.pluck(:created_by_id)).
      where("sms_reminder_sent_at IS NULL OR sms_reminder_sent_at < ?", 4.hours.ago.to_s(:db)).
      group_by(&:user_id).each do |user_id, subscriptions|
      Subscription.where(state: 'unread', user_id: user_id).update_all(sms_reminder_sent_at: Time.now)
      sms_url = "#{Rails.application.secrets.base_urls["app"]}/offers"
      TwilioService.new(User.find(user_id)).send_unread_message_sms(sms_url)
    end
  end
end
