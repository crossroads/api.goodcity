class Message < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :messageable }

  include Paranoid
  include StateMachineScope
  include PushUpdatesForMessage
  include MessageSubscriptions
  include Mentionable

  belongs_to :sender, class_name: "User", inverse_of: :messages

  belongs_to :messageable, polymorphic: true
  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions, source: :subscribable, source_type: "Offer"

  validates :body, presence: true

  default_scope do
    unless User.current_user.try(:can_manage_private_messages?)
      where(is_private: false)
    end
  end

  scope :with_eager_load, -> { includes([:sender]) }
  scope :non_private, -> { where(is_private: false) }
  scope :with_state_for_user, ->(user, state) { joins(:subscriptions).where("subscriptions.user_id = ? and subscriptions.state = ?", user.id, state) }
  scope :filter_by_ids, ->(ids) { where(id: ids.split(",")) }
  scope :filter_by_offer_id, ->(offer_id) { where(messageable_id: offer_id.split(","), messageable_type: "Offer") }
  scope :filter_by_order_id, ->(order_id) { where(messageable_id: order_id.split(","), messageable_type: "Order") }
  scope :filter_by_item_id, ->(item_id) { where(messageable_id: item_id.split(","), messageable_type: "Item") }
  scope :filter_by_package_id, ->(package_id) { where(messageable_id: package_id.split(","), messageable_type: "Package") }

  # used to override the state value during serialization
  attr_accessor :state_value, :is_call_log

  after_create do
    set_mentioned_users
    subscribe_users_to_message # MessageSubscription
    update_client_store # PushUpdatesForMessage (must come after subscribe_users_to_message)
  end

  after_destroy :notify_deletion_to_subscribers

  def parsed_body
    return body if lookup.empty?

    parsed = body
    lookup.each_key { |k| parsed = parsed.gsub("[:#{k}]", lookup[k]["display_name"]) }
    parsed
  end

  def mentioned_ids
    return [] if lookup.empty?

    (lookup.keys || []).map do |k|
      lookup[k]['id'].to_i
    end
  end

  # Marks all messages as read for a user
  # Some refactoring required here. Doesn't understand that an admin may
  # be logged in to Stock and Admin apps and doesn't want all messages to be
  # marked as read
  def mark_read!(user_id, app_name)
    subscriptions.where(user_id: user_id).update_all(state: "read")
    reader = User.find_by(id: user_id)

    send_update("read", Channel.private_channels_for(reader, app_name), "update")
  end

  # Deprication: This will be removed
  def related_object
    @_obj ||= messageable.instance_of?(Item) ? messageable.offer : messageable
  end
end
