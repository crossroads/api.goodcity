class Message < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  belongs_to :recipient, class_name: 'User', inverse_of: :messages
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  scope :with_eager_load, -> {
    eager_load( [:recipient, :sender] )
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

  def notify_message
    PushMessage.new(message: self).notify
  end

  private

  def set_recipient
    self.recipient_id = offer.created_by_id if offer_id
  end

end
