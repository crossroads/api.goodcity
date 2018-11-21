class SubscriptionsReminder

  def generate
    sms_url = "#{Rails.application.secrets.base_urls['app']}/offers"
    donor_unread_subscriptions(donor_users).group_by(&:user_id).each do |user_id, subscriptions|
      begin
        Subscription.where(id: subscriptions.map(&:id)).update_all(sms_reminder_sent_at: Time.now)
        TwilioService.new(User.find(user_id)).send_unread_message_reminder(sms_url)
        Rails.logger.info("\n Message sent to user: #{user_id}")
      rescue Exception => e
        Rails.logger.error("\nError: #{e.message}")
      end
    end
  end

  private

  def donor_users
    Offer.distinct.pluck(:created_by_id)
  end

  def donor_unread_subscriptions(users)
    Subscription.where(state: 'unread', user_id: users).
      where("sms_reminder_sent_at IS NULL OR sms_reminder_sent_at < ?", SUBSCRIPTION_REMINDER_TIME_DELTA.ago)
  end
end
