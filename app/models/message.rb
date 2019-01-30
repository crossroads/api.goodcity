class Message < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid
  include StateMachineScope
  include MessageSubscription
  include UpdateClientStoreAndSendNotification

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
    subscribe_users_to_message # MessageSubscription
    update_client_store #UpdateClientStoreAndSendNotification
    send_new_message_notification #UpdateClientStoreAndSendNotification
  end

  after_destroy :notify_deletion_to_subscribers

  private

  def notify_deletion_to_subscribers
    send_update self, serialized_user(User.current_user), 'read',
      admin_channel - donor_channel - charity_user_channel, ADMIN_APP, :delete
  end

  def charity_user_channel
    return [] unless order
    Channel.private(order.submitted_by_id)
  end

  def admin_channel
    Channel.private(User.staff)
  end

  def donor_channel
    return [] unless offer
    Channel.private(offer.created_by_id)
  end

  def serialized_user(user)
    Api::V1::UserSerializer.new(user)
  end

end
