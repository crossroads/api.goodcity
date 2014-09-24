class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  attr_accessor :state

  belongs_to :recipient, class_name: 'User', inverse_of: :messages
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  scope :with_eager_load, -> {
    eager_load( [:sender] )
  }

  before_save :set_recipient, unless: "is_private"

  def state_for(current_user)
    Subscription.where("user_id=? and message_id=?", current_user.id, id).first.try(:state)
  end

  def self.current_user_messages(current_user, message_id=nil)
    messages_with_state = Message.joins("LEFT OUTER JOIN subscriptions
    ON subscriptions.message_id = messages.id and
    subscriptions.offer_id = messages.offer_id")
    .where('subscriptions.user_id=? or subscriptions.user_id is NULL', current_user)
    .select("messages.*, COALESCE(subscriptions.state, 'never-subscribed') as state")
    message_id.blank? ? messages_with_state : (messages_with_state.where("messages.id =?", message_id).first)
  end

  def notify_message
    if self.subscriptions.subscribed_users(self.sender_id).any?
      PushMessage.new(message: self).notify
    end
  end

  def save_with_subscriptions(subscriptions_details={})
    save
    add_subscription(subscriptions_details[:state])
    #get list of all subscribed users and then insert the records
    subscribe_users_to_message
    # send message to 10 channels at a time
    notify_message
    Message.current_user_messages(sender_id, self.id)
  end

  def subscribe_users_to_message
    list_of_users = offer.users.where("users.id <> ?", sender_id).group('users.id').pluck(:id)
    list_of_users.each do |user|
      add_subscription("unread", user)
    end
  end

  def self.on_offer_submittion(message_details)
    message = Message.create(message_details)
    message.add_subscription("read")
  end

  def add_subscription(state, user_id=nil)
    subscriptions.create(state: state,
      message_id: id,
      offer_id: offer_id,
      user_id: user_id || sender_id)
  end

  private

  def set_recipient
    self.recipient_id = offer.created_by_id if offer_id
  end
end
