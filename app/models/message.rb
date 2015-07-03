class Message < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope

  belongs_to :sender, class_name: "User", inverse_of: :messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  default_scope do
    unless User.current_user.try(:staff?)
      Message.where(is_private: false)
    end
  end

  scope :with_eager_load, -> { includes( [:sender] ) }
  scope :non_private, -> { where(is_private: false) }

  # used to override the state value during serialization
  attr_accessor :state_value, :is_call_log

  after_create do
    subscribe_users_to_message
    update_client_store
    send_new_message_notification
  end

  def mark_read!(user_id)
    self.subscriptions.where(user_id: user_id).update_all(state: 'read')
  end

  def user_subscribed?(user_id)
    subscriptions.where(user_id: user_id).present?
  end

  private

  def subscribe_users_to_message
    users_ids = self.offer.subscribed_users(self.is_private) - [sender_id]
    users_ids.each do |user_id|
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: user_id)
    end
    subscriptions.create(state: "read", message_id: id, offer_id: offer_id, user_id: sender_id) unless sender.try(:system_user?)

    # subscribe donor if not already subscribed
    unless self.is_private || self.offer.cancelled? || self.user_subscribed?(self.offer.created_by_id)
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: self.offer.created_by_id)
    end

    # subscribe assigned reviewer if not already subscribed
    unless self.offer.reviewed_by_id.nil? || self.user_subscribed?(self.offer.reviewed_by_id)
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: self.offer.reviewed_by_id)
    end
  end

  def subscribed_user_channels
    Channel.user_ids(self.offer.subscribed_users(self.is_private))
  end

  def send_new_message_notification
    return if is_call_log
    subscribed_user_channels = subscribed_user_channels()
    text = self.body.truncate(150, separator: ' ')

    # notify subscribed users except sender
    channels = subscribed_user_channels - Channel.user(sender)
    channels -= Channel.user(offer.created_by) if offer.cancelled?

    donor_channel = channels.delete("user_#{offer.created_by_id}")

    service.send_notification(text: text, entity_type: "message",
      entity: self, channel: [donor_channel]) if donor_channel

    service.send_notification(text: text, entity_type: "message",
      entity: self, channel: channels, is_admin_app: true) unless channels.empty?

    # notify all supervisors if no supervisor is subscribed in private thread
    if self.is_private && (Channel.users(User.supervisors) & subscribed_user_channels).empty?
      service.send_notification(text: text, entity_type: "message",
        entity: self, channel: Channel.supervisor, is_admin_app: true)
    end
  end

  def update_client_store
    sender_channel = Channel.user(sender)
    subscribed_user_channels = subscribed_user_channels() - sender_channel
    subscribed_user_channels -= Channel.user(offer.created_by) if offer.cancelled?
    unsubscribed_user_channels = Channel.users(User.staff) -
      subscribed_user_channels - sender_channel

    user = Api::V1::UserSerializer.new(sender)

    send_update self, user, "read", sender_channel unless sender.system_user?
    send_update self, user, 'unread', subscribed_user_channels
    send_update self, user, 'never-subscribed', unsubscribed_user_channels
  end

  def send_update(object, user, state, channel)
    self.state_value = state
    object = Api::V1::MessageSerializer.new(object, {exclude:Message.reflections.keys.map(&:to_sym)})
    PushService.new.send_update_store(channel, {item:object, sender:user, operation: :create}) unless channel.empty?
    self.state_value = nil
  end

  def service
    PushService.new
  end
end
