class SubscriptionsReminder
  def generate
    user_candidates_for_reminder.each do |user|
      user.update(sms_reminder_sent_at: Time.now)
      send_sms_reminder(user)
    end
  end

  private

  # Users who
  #   haven't been reminded in last X hours
  #   have unread messages
  #   have a message sent over 1 hour ago (head start)
  #   are donors with active offers
  #   aren't the sender of the message
  #   its not a private messages
  #   its not order related messages
  #   are reviewers will receive SMS only on offers they have created (exclude offers they are subscribed too)
  # If sms_reminder_sent_at is NULL then use created_at so we don't SMS user immediately
  # IMPORANT NOTE: When a user submits an offer, we set the sms_reminder_sent_at time to now + 1.minute
  #   to avoid alerting on the system 'thank you for submitting your offer' message
  def user_candidates_for_reminder
    offer_states = Offer::SUBSCRIPTIONS_REMINDER_STATES # NOT Draft offers
    User.joins(subscriptions: [:message])
        .joins("INNER JOIN offers on offers.id = messages.messageable_id and messages.messageable_type = 'Offer'")
        .where('COALESCE(users.sms_reminder_sent_at, users.created_at) < (?)', delta.iso8601)
        .where('subscriptions.state': 'unread')
        .where('messages.created_at > COALESCE(users.sms_reminder_sent_at, users.created_at)')
        .where("(messages.messageable_type = 'Offer' OR messages.messageable_type = 'Item')")
        .where('offers.created_by_id = subscriptions.user_id and offers.state IN (?)', offer_states)
        .where('messages.sender_id != offers.created_by_id and messages.created_at < (?)', head_start.iso8601)
        .distinct
  end

  def send_sms_reminder(user)
    sms_url = "#{Rails.application.secrets.base_urls[:app]}/offers"
    TwilioService.new(user).send_unread_message_reminder(sms_url)
    Rails.logger.info(class: self.class.name, msg: "SMS reminder sent", user_id: user.id)
  end

  # Give the user at least 1 hour to read messages before sending SMS
  def head_start
    SUBSCRIPTION_REMINDER_HEAD_START.ago
  end

  # Don't send SMS to a user more often than this time period
  # E.g. 4.hours.ago
  def delta
    SUBSCRIPTION_REMINDER_TIME_DELTA.ago
  end
end
