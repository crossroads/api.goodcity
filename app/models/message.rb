class Message < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope

  belongs_to :sender, class_name: "User", inverse_of: :messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages
  belongs_to :order, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  default_scope do
    unless User.current_user.try(:staff?)
      where("is_private = 'f'")
    end
  end

  scope :with_eager_load, -> { includes([:sender]) }
  scope :non_private, -> { where(is_private: false) }
  scope :donor_messages, ->(donor_id) { joins(:offer).where(offers: { created_by_id: donor_id }, is_private: false) }

  # used to override the state value during serialization
  attr_accessor :state_value, :is_call_log

  after_create do
    subscribe_users_to_message
    # update_client_store
    # send_new_message_notification
  end

  after_destroy :notify_deletion_to_subscribers

  def mark_read!(user_id)
    self.subscriptions.where(user_id: user_id).update_all(state: 'read')
    reader = User.find_by(id: user_id)
    app_name = reader.staff? ? ADMIN_APP : DONOR_APP
    send_update(self, serialized_user(reader), "read", Channel.private(reader), app_name)
  end

  def user_subscribed?(user_id)
    subscriptions.where(user_id: user_id).present?
  end

  private

  def serialized_user(user)
    Api::V1::UserSerializer.new(user)
  end

  def subscribe_users_to_message
    if offer
      users_ids = offer.subscribed_users(is_private) - [sender_id]
      users_ids.each{ |user_id| add_subscription("unread", user_id, offer_id: offer_id ) }
      subscribe_sender unless sender.try(:system_user?)
      subscribe_donor unless donor_subscribed?
      subscribe_reviewer unless reviewer_subscribed?
    elsif order
      users_ids = order.subscribed_users(is_private) - [sender_id]
      users_ids.each{ |user_id| add_subscription("unread", user_id, order_id: order_id) }
      subscribe_sender unless sender.try(:system_user?)
      subscribe_order_creator unless order_creator_subscribed?
      subscribe_order_processor if order_processor_present? && !order_processor_subscribed?
    end
  end

  def subscribe_reviewer
    add_subscription("unread", offer.reviewed_by_id, offer_id: offer_id)
  end

  def subscribe_sender
    if offer
      add_subscription("read", sender_id, offer_id: offer_id)
    elsif order
      add_subscription("read", sender_id, order_id: order_id)
    end
  end

  def subscribe_order_processor
    add_subscription("unread", order.processed_by_id, order_id: order_id)
  end

  def subscribe_order_creator
    add_subscription("unread", order.created_by_id, order_id: order_id)
  end

  def subscribe_donor
    add_subscription("unread", offer.created_by_id, offer_id: offer_id)
  end

  def order_creator_subscribed?
    is_private || order.cancelled? || user_subscribed?(order.created_by_id)
  end

  def order_processor_present?
    order.processed_by_id.present?
  end

  def order_processor_subscribed?
    is_private || order.cancelled? || user_subscribed?(order.processed_by_id)
  end

  def donor_subscribed?
    is_private || offer.cancelled? || user_subscribed?(offer.created_by_id)
  end

  def reviewer_subscribed?
    offer.reviewed_by_id.nil? || user_subscribed?(offer.reviewed_by_id)
  end

  def add_subscription(state, user_id, offer_id=nil, order_id=nil)
    subscriptions.create(
      state: state,
      message_id: id,
      offer_id: offer_id,
      order_id: order_id,
      user_id: user_id)
  end

  def subscribed_user_channels
    if offer
      Channel.private(offer.subscribed_users(is_private))
    elsif order
      Channel.private(order.subscribed_users(is_private))
    end
  end

  def send_new_message_notification
    return if is_call_log
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

  def update_client_store
    sender_channel = Channel.private(sender)
    subscribed_user_channels = subscribed_user_channels() - sender_channel - donor_channel
    unsubscribed_user_channels = admin_channel - subscribed_user_channels - sender_channel - donor_channel

    user = serialized_user(sender)

    if sender_channel == donor_channel
      send_update self, user, "read", donor_channel, DONOR_APP unless offer.cancelled? || is_private
    else
      send_update self, user, "read", sender_channel, ADMIN_APP unless sender.system_user?
      send_update self, user, "unread", donor_channel, DONOR_APP unless offer.cancelled? || is_private
    end
    send_update self, user, 'unread', subscribed_user_channels, ADMIN_APP
    send_update self, user, 'never-subscribed', unsubscribed_user_channels, ADMIN_APP
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
      offer_id:   offer.id,
      item_id:    item.try(:id),
      author_id:  sender_id,
      message_id: id
    } unless channel.empty?
  end

  def notify_deletion_to_subscribers
    send_update self, serialized_user(User.current_user), 'read',
      admin_channel - donor_channel, ADMIN_APP, :delete
  end

  def admin_channel
    Channel.private(User.staff)
  end

  def donor_channel
    Channel.private(offer.created_by_id)
  end

  def supervisors_channel
    Channel.private(User.supervisors)
  end

  def serialized_message(object)
    associations = Message.reflections.keys.map(&:to_sym)
    Api::V1::MessageSerializer.new(object, { exclude: associations })
  end
end
