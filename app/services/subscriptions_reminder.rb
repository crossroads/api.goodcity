class SubscriptionsReminder

  def generate
    users_to_remind.each do |user_id, subscriptions|
      user = User.find(user_id)
      user.update(sms_reminder_sent_at: Time.zone.now)
      send_sms_reminder(user)
    end
  end

  private

  # Get list of subscriptions distinct by user where user is donor and hasn't received reminder since

  def users_to_remind
    donor_ids = Offer.distinct.pluck(:created_by_id).compact

    User.joins(subscriptions: [:messages]).where(
     'id IN (?) AND
     subscriptions.state = (?) AND
     MIN(messages.created_at) > users.sms_reminder_sent_at AND
     MIN(messages.created_at) > (?)',
     donor_ids, 'unread', delta
    ).distinct('id')

    # Subscription.
    #   joins(:message, :user).
    #   where('users.id IN (?) AND 
    #     subscriptions.state = (?) AND
    #     MIN(messages.created_at) > users.sms_reminder_sent_at AND
    #     MIN(messages.created_at) > (?)',
    #     donor_ids, 'unread', delta)
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
