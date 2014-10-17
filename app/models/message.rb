class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  attr_accessor :state

  belongs_to :recipient, class_name: "User", inverse_of: :messages
  belongs_to :sender, class_name: "User", inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  scope :with_eager_load, ->{ eager_load( [:sender] ) }

  before_save :set_recipient, unless: "is_private"

  def state_for(current_user)
    Subscription.where("user_id=? and message_id=?", current_user.id, id).first.try(:state)
  end

  def self.current_user_messages(current_user, message_id=nil)
    messages_with_state = Message.joins("LEFT OUTER JOIN subscriptions
    ON subscriptions.message_id = messages.id and
    subscriptions.offer_id = messages.offer_id").
    where("subscriptions.user_id=? or subscriptions.user_id is NULL", current_user).
    select("messages.*, COALESCE(subscriptions.state, 'never-subscribed') as state")

    message_id.blank? ? messages_with_state : (messages_with_state.where("messages.id =?", message_id).first)
  end

  def notify_message
    channel_listeners = list_of_listeners
    if channel_listeners.any?
      PushMessage.new({message: self, channel: channel_listeners}).notify
    end
  end

  def save_with_subscriptions(subscriptions_details={})
    save
    # added sender as subscriber
    add_subscription(subscriptions_details[:state])
    subscribe_users_to_message
    notify_message
    Message.current_user_messages(sender_id, self.id)
  end

  def subscribe_users_to_message
    if (sender_permission.blank? || !is_private?)
      list_of_users = offer.subscriptions.subscribed_users(sender_id).pluck(:user_id)
    else
      list_of_users = offer.subscriptions.subscribed_privileged_users(sender_id).pluck(:user_id)
    end
    list_of_users.each do |user_id|
      add_subscription("unread", user_id)
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

  def sender_permission
    User.find(sender_id).try(:permission).try(:name)
  end

  def set_recipient
    self.recipient_id = offer.created_by_id if offer_id
  end

  def list_of_listeners
    case [sender_permission.present?, is_private?]
    when[true, true]
      list_of_reviewer_or_supervisor(sender_permission)
    else
       subscribed_users = offer.subscriptions.subscribed_users(sender_id)
      if subscribed_users.length === 0
        User.reviewers.pluck(:id).map{ |id| "user_#{id}" }
      else
        channel_for_subscribed_all_users
      end
    end
  end

  def list_of_reviewer_or_supervisor(sender_permission)
    subscribed_users = offer.subscriptions.subscribed_privileged_users(sender_id)
    # if sender is Reviewer then get data for supervisor and vice-versa
    admins = sender_permission == "Reviewer" ? User.supervisors : User.reviewers
    if subscribed_users.length === 0
      admins.pluck(:id).map{ |id| "user_#{id}" }
    else
      channel_for_subscribed_privilaged_users()
    end
  end

  def channel_for_subscribed_all_users
    offer.subscriptions.subscribed_users(sender_id).map do |subscriber|
      "user_#{subscriber.user_id}"
    end
  end

  def channel_for_subscribed_privilaged_users
    offer.subscriptions.subscribed_privileged_users(sender_id).map do |subscriber|
      "user_#{subscriber.user_id}"
    end
  end
end
