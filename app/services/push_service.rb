class PushService

  class PushServiceError < StandardError; end

  attr_accessor :channel, :event, :data, :resync

  def initialize(options = {})
    @channel = options[:channel]
    @event   = options[:event]
    @data    = options[:data]
    @resync  = options[:resync] || false
  end

  def notify
    %w(channel event data).each do |opt|
      raise PushServiceError, "'#{opt}' has not been set" if send(opt).blank?
    end

    PusherJob.perform_later([channel].flatten, event, data.to_json, resync)
  end

  def send_update_store(channel, data)
    @channel = channel
    @event   = "update_store"
    @data    = data
    @resync  = true
    notify
  end

  def send_new_offer_notification(channel:, offer:, is_admin_app: false)
    send_notification channel: channel, is_admin_app: is_admin_app, data: {
      category:   'new_offer',
      message:    I18n.t("notification.new_offer", name: offer.created_by.full_name),
      offer_id:   offer.id,
      author_id:  offer.created_by_id
    }
  end

  def send_new_message_notification(channel:, message_object:, is_admin_app: false)
    send_notification channel: channel, is_admin_app: is_admin_app, data: {
      category:   'message',
      message:    message_object.body.truncate(150, separator: ' '),
      is_private: message_object.is_private,
      offer_id:   message_object.offer.id,
      item_id:    message_object.item.try(:id),
      author_id:  message_object.sender_id
    }
  end

  def send_incoming_call_notification(channel:, donor_id:, donor_name:)
    send_notification channel: channel, is_admin_app: true, data: {
      category:   'incoming_call',
      message:    "#{donor_name} calling now..",
      author_id:  donor_id
    }
  end

  def send_call_answered_notification(channel:, donor_id:, donor_name:, receiver_name:)
    send_notification channel: channel, is_admin_app: true, data: {
      category:   'call_answered',
      message:    "Call from #{donor_name} has been accepted by #{receiver_name}",
      author_id:  donor_id
    }
  end

  private

  def send_notification(channel:, is_admin_app:, data:)
    @data = data
    @data[:date] = Time.now.to_json.tr('"','')
    @channel = channel
    @event   = "notification"
    notify

    if Channel.user_channel?(channel)
      AzureNotifyJob.perform_later(channel, data, is_admin_app)
    end
  end
end
