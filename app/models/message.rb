class Message < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :recipient, class_name: 'User', inverse_of: :messages
  belongs_to :sender, class_name: 'User', inverse_of: :sent_messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages

  after_create :notify_message

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
    PushMessage.new(message: self).notify_new_message
  end

end
