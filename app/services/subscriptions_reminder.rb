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
  #   are donors with active offers
  #   aren't the author of the message
  # If sms_reminder_sent_at is NULL then use created_at so we don't SMS user immediately
  def user_candidates_for_reminder
    states = ['submitted', 'under_review', 'reviewed', 'scheduled', 'received',
      'receiving', 'inactive'] # NOT draft, closed or cancelled
    user_ids = Offer.where(state: states).distinct.pluck(:created_by_id)
    User.joins(subscriptions: [:message]).
      where('users.id IN (?)', user_ids).
      where("COALESCE(users.sms_reminder_sent_at, users.created_at) < (?)", delta.iso8601).
      where('subscriptions.state': 'unread').
      where("messages.created_at > COALESCE(users.sms_reminder_sent_at, users.created_at)").
      where('messages.sender_id != users.id').
      distinct
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
