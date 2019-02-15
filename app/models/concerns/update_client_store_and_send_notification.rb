#
# Updation of client store logic for messages is extracted here
# to avoid cluttering the model class
module UpdateClientStoreAndSendNotification
  extend ActiveSupport::Concern

  def mark_read!(user_id)
    subscriptions.where(user_id: user_id).update_all(state: 'read')
    reader = User.find_by(id: user_id)
    app_name = reader.staff? ? ADMIN_APP : DONOR_APP
    send_update('read', Channel.private(reader), app_name)
  end

  def update_client_store
    sender_channel = Channel.private(sender)
    app_name, channel_name = fetch_browse_or_donor(sender_channel)

    if from_donor_or_browse?(channel_name)
      # if message sent from browse || donor update self
      send_update('read', channel_name, app_name)
    elsif from_stock_app?
      # update browse & stock if message sent from stock
      send_update('read', sender_channel, STOCK_APP)
      send_update('unread', browse_channel, BROWSE_APP)
    elsif object == offer
      # update admin and donor if message sent from admin
      send_update('read', sender_channel, ADMIN_APP) unless sender.system_user?
      send_update('unread', donor_channel, DONOR_APP) unless object.cancelled? || is_private
    end

    send_update_to_subscribed_and_unsubscribed_channels
  end

  def send_new_message_notification
    # notifications are outsite initial scope for browse and
    # stock and will be taken care later.

    return if order || is_call_log

    subscribed_user_channels = subscribed_user_channels()
    current_channel = Channel.private(sender)

    # notify subscribed users except sender
    sender_channel = current_channel
    channels = subscribed_user_channels - sender_channel - donor_channel

    unless is_private || offer.cancelled? || donor_channel == sender_channel
      send_notification(donor_channel, DONOR_APP)
    end
    send_notification(channels, ADMIN_APP)

    # notify all supervisors if no supervisor is subscribed in private thread
    if is_private && ((supervisors_channel - current_channel) & subscribed_user_channels).empty?
      send_notification(Channel::SUPERVISOR_CHANNEL, ADMIN_APP)
    end
  end

  private

  def send_update_to_subscribed_and_unsubscribed_channels
    discard_channels = sender_channel + donor_channel + browse_channel
    subscribed_user_channels = (subscribed_user_channels() - discard_channels).uniq
    unsubscribed_user_channels = (admin_channel - discard_channels).uniq

    send_update('unread', subscribed_user_channels, fetch_reciever_app)
    send_update('never-subscribed', unsubscribed_user_channels, fetch_reciever_app)
  end

  def send_update(state, channel, app_name, operation = :create)
    self.state_value = state
    message_from_stock = from_stock_app? if order

    PushService.new.send_update_store channel, app_name, {
      item: serialized_message(self), sender: serialized_user(sender),
      operation: operation, message_from_stock: message_from_stock } unless channel.empty?
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

  def from_donor_or_browse?(channel_name)
    sender_channel == channel_name && !object.cancelled? && !is_private
  end

  def from_stock_app?
    stock_channel.include?(sender_channel.first) &&
      object == order && !object.cancelled? && !is_private?
  end

  def fetch_reciever_app
    object == offer ? ADMIN_APP : STOCK_APP
  end

  # determine which app and which channel to send notification to.
  def fetch_browse_or_donor(sender_channel)
    case sender_channel
    when donor_channel
      [DONOR_APP, donor_channel]
    when browse_channel
      [BROWSE_APP, browse_channel]
    end
  end

  def subscribed_user_channels
    Channel.private(object.subscribed_users(is_private))
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

  def serialized_message(obj)
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(obj, { exclude: associations })
  end

  def object
    offer || order
  end
end
