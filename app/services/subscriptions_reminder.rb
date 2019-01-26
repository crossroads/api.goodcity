class SubscriptionsReminder

  def generate
    users_with_unread_messages.each do |user|

      oldest_unread_message = user.subscriptions.unread.map{|s| s.message.created_at}.min
      if oldest_unread_message > max(user.sms_reminder_sent_at, delta)
        user.update(sms_reminder_sent_at: Time.zone.now)
        send_sms_reminder(user)
      end

      # Better to start with messages created in last 'delta' hours and find users who haven't been reminded in last 4 hours

    end
  end

  private

  # Get list of subscriptions distinct by user where user is donor and hasn't received reminder since

  def users_to_remind
    user_ids = Offer.distinct.pluck(:created_by_id).compact
    # User.joins(subscriptions: [:message]).where(id: user_ids, 'subscriptions.state': 'unread').group('users.id, sms_reminder_sent_at').having("MIN(messages.created_at) > sms_reminder_sent_at AND MIN(messages.created_at) > '#{delta}'").distinct(:id)    
    # GREATEST(sms_reminder_sent_at, '#{delta}')").distinct(:id)
  end

  def users_with_unread_messages
    user_ids = Offer.distinct.pluck(:created_by_id).compact
    User.joins(:subscriptions).
      where(id: user_ids, 'subscriptions.state': 'unread').distinct(:id)
  end

  def send_sms_reminder(user)
    sms_url = "#{Rails.application.secrets.base_urls['app']}/offers"
    TwilioService.new(user).send_unread_message_reminder(sms_url)
    Rails.logger.info("SMS reminder sent to user #{user.id}")
  end

  # E.g. 4.hours.ago
  def delta
    SUBSCRIPTION_REMINDER_TIME_DELTA.ago
  end

end
