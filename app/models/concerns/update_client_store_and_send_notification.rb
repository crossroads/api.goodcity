#
# Updation of client store logic for messages is extracted here to avoid cluttering the model class
module UpdateClientStoreAndSendNotification
  extend ActiveSupport::Concern

  def mark_read!(user_id)
    self.subscriptions.where(user_id: user_id).update_all(state: 'read')
    reader = User.find_by(id: user_id)
    app_name = if reader.staff?
        ADMIN_APP
      elsif reader.charity?
        BROWSE_APP
      elsif reader.order_fulfilment?
        STOCK_APP
      else
        DONOR_APP
      end
    send_update(self, serialized_user(reader), "read", Channel.private(reader), app_name)
  end

  def update_client_store
    sender_channel = Channel.private(sender)
    subscribed_user_channels = subscribed_user_channels() - sender_channel - donor_channel - browse_channel

    unsubscribed_user_channels = admin_channel - subscribed_user_channels - sender_channel - donor_channel - browse_channel

    object = offer || order
    user = serialized_user(sender)
    app_name, channel_name = fetch_browse_or_donor(sender_channel)
    if sender_channel == channel_name
      # if message sent from browse || donor update self
      send_update self, user, "read", channel_name, app_name unless object.cancelled? || is_private
    elsif stock_channel.include?(sender_channel.first) && object == order
      # update browse & stock if message sent from stock
      unless object.cancelled? || is_private
        debugger
        send_update self, user, "read", sender_channel, STOCK_APP
        send_update self, user, 'unread', browse_channel, BROWSE_APP
      end
    elsif object == offer
      send_update self, user, "read", sender_channel, ADMIN_APP unless sender.system_user?
      send_update self, user, "unread", donor_channel, DONOR_APP unless object.cancelled? || is_private
    end

    if object == order && app_name == BROWSE_APP
      send_update self, user, 'unread', subscribed_user_channels.uniq, STOCK_APP
      send_update self, user, 'never-subscribed', unsubscribed_user_channels.uniq, STOCK_APP
    elsif object == offer && app_name == DONOR_APP
      send_update self, user, 'unread', subscribed_user_channels.uniq, ADMIN_APP
      send_update self, user, 'never-subscribed', unsubscribed_user_channels.uniq, ADMIN_APP
    end
  end

  def send_new_message_notification
    # notifications are outsite initial scope for browse and stock and will be taken care later.
    return if order || is_call_log
    subscribed_user_channels = subscribed_user_channels()
    current_channel = Channel.private(sender)

    # notify subscribed users except sender
    sender_channel = current_channel
    channels = subscribed_user_channels - sender_channel - donor_channel

    send_notification(donor_channel, DONOR_APP) unless is_private || offer.cancelled? || donor_channel == sender_channel
    send_notification(channels, ADMIN_APP)

    # notify all supervisors if no supervisor is subscribed in private thread
    if is_private && ((supervisors_channel - current_channel) & subscribed_user_channels).empty?
      send_notification(Channel.supervisor, ADMIN_APP)
    end
  end

  private
  # determine which app and which channel to send notification to.
  def fetch_browse_or_donor(sender_channel)
    if sender_channel == donor_channel
      app_name  = DONOR_APP
      channel_name = donor_channel
    elsif sender_channel == browse_channel
      app_name = BROWSE_APP
      channel_name = browse_channel
    end
    return [app_name, channel_name]
  end

  def subscribed_user_channels
    obj = offer || order
    Channel.private(obj.subscribed_users(is_private))
  end

  def send_update(object, user, state, channel, app_name, operation = :create)
    self.state_value = state
    PushService.new.send_update_store channel, app_name, {
      item: serialized_message(object), sender: user,
      operation: operation } unless channel.empty?
    self.state_value = nil
  end

  def send_notification(channel, app_name)
    PushService.new.send_notification channel, app_name, {
      category:   'message',
      message:    body.truncate(150, separator: ' '),
      is_private: is_private,
      offer_id:   offer.try(:id),
      item_id:    item.try(:id),
      author_id:  sender_id,
      message_id: id
    } unless channel.empty?
  end

  def sender_channel
    Channel.private(sender)
  end

  def stock_channel
    Channel.private(User.staff)
  end

  def admin_channel
    Channel.private(User.staff)
  end

  def donor_channel
    return [] unless offer
    Channel.private(offer.created_by_id)
  end

  def browse_channel
    return [] unless order
    Channel.private(order.created_by_id)
  end

  def supervisors_channel
    Channel.private(User.supervisors)
  end

  def serialized_user(user)
    Api::V1::UserSerializer.new(user)
  end

  def serialized_message(object)
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(object, { exclude: associations })
  end
end
