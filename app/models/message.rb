class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  belongs_to :recipient, class_name: 'User', inverse_of: :messages
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions

  scope :with_eager_load, -> {
    eager_load( [:sender] )
  }

  after_create :notify_message
  before_save :set_recipient, unless: "is_private"

  state_machine :state, initial: :unread do
    state :unread, :read, :replied

    event :read do
      transition :unread => :read
    end

    event :unread do
      transition :read => :unread
    end

    event :reply do
      transition [:read, :unread] => :replied
    end
  end

  def self.current_user_messages(current_user, message_id=nil)
    messages_with_state = Message.joins("LEFT OUTER JOIN subscriptions
    ON subscriptions.message_id = messages.id and
    subscriptions.offer_id = messages.offer_id")
    .where('subscriptions.user_id=?', current_user)
    .select("messages.* , subscriptions.state as message_state")
    message_id.blank? ? messages_with_state : (messages_with_state.where("messages.id =?", message_id).first)
  end

  def notify_message
    PushMessage.new(message: self).notify
  end

  def save_with_subscriptions(subscriptions_details={})
    self.save
    self.subscriptions.create(state: subscriptions_details[:state],
      message_id: id,
      offer_id: offer_id,
      user_id: sender_id)
    Message.current_user_messages(sender_id, self.id)
    #get list of all subscribed users and then insert the records
  end

  private

  def set_recipient
    self.recipient_id = offer.created_by_id if offer_id
  end


end
