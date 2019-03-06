# For each new message, send a push update to the
# - sender
# - creator (unless is_private or offer/order cancelled)
# - reviewers/supervisors/order_fulfillers individually so we can 
#     include message state: 'read', 'unread', 'never-subscribed'
module PushUpdatesForMessage
  extend ActiveSupport::Concern

  def update_client_store
    user_ids = []
    obj = self.related_object

    # Send update to creator (donor or charity)
    user_ids << obj.try(:created_by_id)
    user_ids << self.sender_id

    # All reviewers/supervisors/order_fulfillers
    user_ids += User.reviewers.pluck(:id)
    user_ids += User.supervisors.pluck(:id)
    user_ids += User.order_fulfilment.pluck(:id)

    # Don't send updates to system users
    # Don't send to donor/charity if is private message or offer/order is cancelled
    user_ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]
    user_ids -= [obj.try(:created_by_id)] if is_private or obj.try(:cancelled?)

    # Group all the channels by state
    state_groups = {}
    user_ids.flatten.compact.uniq.each do |user_id|
      state = state_for_user(user_id)
      app_name = app_name_for_user(user_id)
      channel = Channel.private_channels_for(user_id, app_name)
      state_groups[state] = ((state_groups[state] || []) + channel)
    end

    # For each message state (read/unread/never-subscribed) send 
    #   push updates to all the channels
    state_groups.each do |state, channels|
      send_update(state, channels.flatten)
    end
  end

  # All reviewers/supervisors/order_fulfillers
  def notify_deletion_to_subscribers
    if object_class == "Order"
      channels = [Channel::ORDER_FULFILMENT_CHANNEL]
    else # Offer/Item
      channels = [Channel::REVIEWER_CHANNEL, Channel::SUPERVISOR_CHANNEL]
    end
    send_update('read', channels, :delete)
  end

  private

  def send_update(state, channels, operation = :create)
    data = {
      item: serialized_message(state),
      sender: serialized_user(sender),
      operation: operation
    }
    PushService.new.send_update_store(channels, data)
  end

  # Need to inject subscription.state into message data 
  #   because read/unread state is per subscription not per message
  def serialized_message(state)
    message = self.tap{|m| m.state_value = state}
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(message, { exclude: associations })
  end

  def serialized_user(user)
    # TODO: handle (user_summary: true) option
    Api::V1::UserSerializer.new(user)
  end

  def object_class
    self.related_object.class.name
  end

  # Mark message state as
  #  'read' if user is message sender
  #  'never-subscribed' if going to an admin who hasn't messaged on the thread
  #  'unread' - for subscribed users
  def state_for_user(user_id)
    if self.sender_id == user_id
      'read'
    else
      subscribed_user_ids.include?(user_id) ? 'unread' : 'never-subscribed'
    end
  end

  def app_name_for_user(user_id)
    obj = self.related_object
    created_by_id = obj.try(:created_by_id) || obj.try(:offer).try(:created_by_id)
    if object_class == 'Order'
      (created_by_id == user_id) ? BROWSE_APP : STOCK_APP
    else # Offer/Item
      (created_by_id == user_id) ? DONOR_APP : ADMIN_APP
    end
  end

  # Cached array of user ids subscribed to the message
  def subscribed_user_ids
    @subscribed_user_ids ||= self.subscriptions.pluck(:user_id)
  end

end
