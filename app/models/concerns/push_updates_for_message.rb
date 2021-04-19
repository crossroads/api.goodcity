# For each new message, send a push update to the
# - sender
# - creator (unless is_private or offer/order cancelled)
# - staff apps: to admin app if message on offer / to stock app if message on order
# - send to admin staff users individually so we can
#     include message state: 'read', 'unread', 'never-subscribed'
#
module PushUpdatesForMessage
  extend ActiveSupport::Concern

  def update_client_store
    user_ids = []
    obj = self.related_object
    # Send update to recipient (donor or charity)
    user_ids << self.recipient_id unless is_private || obj.try(:cancelled?)
    user_ids << self.sender_id

    # All admin users with permission to view messages on that object
    user_ids += relevant_staff_user_ids
    # Don't send updates to system users
    # Don't send to donor/charity if is private message or offer/order is cancelled
    user_ids -= [User.system_user.try(:id), User.stockit_user.try(:id)]

    # Group all the channels by state
    state_groups = {}
    user_ids.flatten.compact.uniq.each do |user_id|
      state = state_for_user(user_id)
      app_names = app_names_for_user(user_id) || []
      app_names.each do |app_name|
        channel = Channel.private_channels_for(user_id, app_name)
        state_groups[state] = ((state_groups[state] || []) + channel)
      end
    end

    # For each message state (read/unread/never-subscribed) send
    #   push updates to all the channels
    state_groups.each do |state, channels|
      send_update(state, channels.flatten)
    end
  end

  # All reviewers/supervisors/order_fulfillers
  def notify_deletion_to_subscribers
    case object_class
    when 'Order'
      channels = [Channel::ORDER_FULFILMENT_CHANNEL]
    when 'Package'
      channels = [Channel::INVENTORY_CHANNEL]
    else # Offer / Item
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
    message = self.tap { |m| m.state_value = state }
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(message, { exclude: associations })
  end

  def serialized_user(user)
    Api::V1::UserSerializer.new(user, user_summary: true)
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

  def app_names_for_user(user_id)
    obj = self.related_object
    owner_id = messageable_owner_id

    if object_class == 'Order'
      return [owner_id == user_id ? BROWSE_APP : STOCK_APP]
    end

    return [STOCK_APP] if object_class == 'Package'

    if %w[Offer Item].include?(object_class)
      to = []
      to << DONOR_APP if owner_id == user_id
      to << (user_id == recipient_id ? BROWSE_APP : ADMIN_APP)
      to.flatten.uniq
    end
  end

  # Cached array of user ids subscribed to the message
  def subscribed_user_ids
    @subscribed_user_ids ||= self.subscriptions.pluck(:user_id)
  end

  # All admin users with permission to view messages on that object
  def relevant_staff_user_ids
    if %w[Offer Item].include?(object_class)
      message_permissions = ['can_manage_offer_messages']
    elsif object_class == 'Order'
      message_permissions = ['can_manage_order_messages']
    elsif object_class == 'Package'
      message_permissions = ['can_manage_package_messages']
    else
      message_permissions = []
    end
    User.joins(roles: [:permissions]).where(permissions: { name: message_permissions }).distinct.pluck(:id)
  end
end
