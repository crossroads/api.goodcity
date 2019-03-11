class Message < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include MessageSubscription
  include PushUpdatesForMessage

  belongs_to :sender, class_name: 'User', inverse_of: :messages
  belongs_to :offer, inverse_of: :messages
  belongs_to :item, inverse_of: :messages
  belongs_to :order, inverse_of: :messages

  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: 'Offer', through: :subscriptions

  validates :body, presence: true

  default_scope do
    unless User.current_user.try(:staff?)
      where("is_private = 'f'")
    end
  end

  scope :with_eager_load, -> { includes([:sender]) }
  scope :non_private, -> { where(is_private: false) }
  scope :donor_messages, ->(donor_id) { joins(:offer).where(offers: { created_by_id: donor_id }, is_private: false) }
  scope :with_user_read_state, ->(user, state) { joins(:subscriptions).where("subscriptions.user_id = ? and subscriptions.state = ?", user.id, state) }

  # used to override the state value during serialization
  attr_accessor :state_value, :is_call_log

  after_create do
    subscribe_users_to_message # MessageSubscription
    update_client_store # PushUpdatesForMessage (must come after subscribe_users_to_message)
  end

  after_destroy :notify_deletion_to_subscribers

  # Marks all messages as read for a user
  # Some refactoring required here. Doesn't understand that an admin may
  # be logged in to Stock and Admin apps and doesn't want all messages to be
  # marked as read
  def mark_read!(user_id, app_name)
    subscriptions.where(user_id: user_id).update_all(state: 'read')
    reader = User.find_by(id: user_id)

    send_update('read', Channel.private_channels_for(reader, app_name), 'update')
  end

  # To make up for the lack of polymorphism between offer/item/order. Cached
  def related_object
    @_obj ||= (offer || order || item)
  end
end
