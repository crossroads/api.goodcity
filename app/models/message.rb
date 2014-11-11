class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  belongs_to :sender, class_name: "User", inverse_of: :messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  scope :with_eager_load, -> { includes( [:sender] ) }

  # select messages with current user state
  default_scope do
    if User.current.nil?
      logger.warn("Warning: User.current is nil in Message.default_scope")
      nil
    else
      joins("left join subscriptions s on s.message_id = messages.id and s.user_id = #{User.current.id}").
        select("messages.*, coalesce(s.state, 'never-subscribed') as state")
    end
  end

  after_create do
    subscribe_users_to_message
    update_ember_store
    send_new_message_notification
  end

  after_initialize :init_state

  # state can be accessed on objects returned from db due to default_scope but not on new objects
  # can't use attr_accessor because db retrieved values are stored in @attributes
  # init_state is used to ensure "state" exists on @attributes for json serialization
  def init_state
    self.state = nil unless @attributes.key?("state")
  end

  def state
    @attributes["state"]
  end

  def state=(value)
    @attributes["state"] = value
  end

  def mark_read!(user_id)
    subscription = self.subscriptions.find_by_user_id(user_id)
    subscription.update_attribute("state", "read") if subscription
  end

  private

  def subscribe_users_to_message
    users_ids = self.offer.subscribed_users(self.is_private).pluck(:id) - [sender_id]
    users_ids.each do |user_id|
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: user_id)
    end
    subscriptions.create(state: self.state, message_id: id, offer_id: offer_id, user_id: sender_id)

    # subscribe donor if not already subscribed
    if !self.is_private && subscriptions.where(user_id: self.offer.created_by_id).empty?
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: self.offer.created_by_id)
    end

    # subscribe assigned reviewer if not already subscribed
    if !self.offer.reviewed_by_id.nil? && subscriptions.where(user_id: self.offer.reviewed_by_id).empty?
      subscriptions.create(state: "unread", message_id: id, offer_id: offer_id, user_id: self.offer.reviewed_by_id)
    end
  end

  def subscribed_user_channels
    Channel.users(self.offer.subscribed_users(self.is_private))
  end

  def send_new_message_notification
    subscribed_user_channels = subscribed_user_channels()
    text = self.body.truncate(150, separator: ' ')

    # notify subscribed users except sender
    channels = subscribed_user_channels - Channel.user(self.sender)
    service.send_notification(text: text, entity_type: "message", entity: self, channel: channels) unless channels.empty?

    # notify all supervisors if no supervisor is subscribed in private thread
    if self.is_private && (Channel.users(User.supervisors) & subscribed_user_channels).empty?
      service.send_notification(text: text, entity_type: "message", entity: self, channel: Channel.supervisor)
    end
  end

  def update_ember_store
    sender_channel = Channel.user(self.sender) #remove sender channel to prevent duplicates
    subscribed_user_channels = subscribed_user_channels() - sender_channel
    unsubscribed_user_channels = Channel.users(User.staff) - subscribed_user_channels - sender_channel

    orig_state = self.state
    self.state = "unread"
    service.update_store(data: self, channel: subscribed_user_channels) unless subscribed_user_channels.empty?
    self.state = "never-subscribed"
    service.update_store(data: self, channel: unsubscribed_user_channels) unless unsubscribed_user_channels.empty?
    self.state = orig_state
  end

  private
  def service
    PushService.new
  end

end
