#
# Message Model
#
# Messages have a few important fields:
#   - messageable           A goodcity record (e.g offer) being discussed
#   - sender_id             The person sending the message
#   - recipient_id (opt)    Some outsider you're discussing the record with
#   - is_private            Whether the message is internal (within staff members) or not
#
# There are 2 kinds of messages, 'private' and 'public' messages.
#
# > Private Messages
#   Those messages are destined to Crossroads staff members, they relate to a record (e.g an offer) of Goodcity
#   Other users, such as the donor of the offer, never hear about them
#
#   >> Expectations
#     - Sender is always an entitled staff member (at time of creation)
#     - Recipient is ALWAYS NULL
#
# > Public Messages
#   These messages are between Crossroads staff members and users. The current use cases are
#     - Staff members want to talk to a donor about one of their offers
#     - Staff members want to talk to a charity ABOUT one offer
#
#   >> Expectations
#     - Sender is an entitled staff member OR a user
#     - Recipient should be PRESENT -- Will be defaulted to the owner of the record if not
#
#
class Message < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :messageable }

  include Paranoid
  include StateMachineScope
  include PushUpdatesForMessage
  include MessageSubscriptions
  include Mentionable

  belongs_to :sender, class_name: "User", inverse_of: :messages
  belongs_to :recipient, class_name: "User"

  belongs_to :messageable, polymorphic: true
  has_many :subscriptions, dependent: :destroy
  has_many :offers_subscription, class_name: "Offer", through: :subscriptions, source: :subscribable, source_type: "Offer"

  validates :body, presence: true
  scope :with_eager_load, -> { includes([:sender]) }
  scope :non_private, -> { where(is_private: false) }
  scope :with_state_for_user, ->(user, state) { joins(:subscriptions).where("subscriptions.user_id = ? and subscriptions.state = ?", user.id, state) }
  scope :filter_by_ids, ->(ids) { where(id: ids.split(",")) }
  scope :filter_by_offer_id, ->(offer_id) { where(messageable_id: offer_id.split(","), messageable_type: "Offer") }
  scope :filter_by_order_id, ->(order_id) { where(messageable_id: order_id.split(","), messageable_type: "Order") }
  scope :filter_by_offer_response_id, ->(offer_response_id) { where(messageable_id: offer_response_id.split(","), messageable_type: "OfferResponse") }
  scope :filter_by_item_id, ->(item_id) { where(messageable_id: item_id.split(","), messageable_type: "Item") }
  scope :filter_by_package_id, ->(package_id) { where(messageable_id: package_id.split(","), messageable_type: "Package") }
  scope :from_humans, ->() { where.not(sender_id: non_human_senders) }

  before_save :resolve_recipient

  # used to override the state value during serialization
  attr_accessor :state_value, :is_call_log

  after_create do
    set_mentioned_users
    subscribe_users_to_message # MessageSubscription
    update_client_store # PushUpdatesForMessage (must come after subscribe_users_to_message)
  end

  after_destroy :notify_deletion_to_subscribers

  def self.non_human_senders
    [User.system_user.try(:id), User.stockit_user.try(:id)].compact
  end

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

  #
  # To ensure backwards compatibility, when a message is saved without a recipient we detect that and use the record to infer it
  #
  def resolve_recipient
    if recipient_id.present?
      raise Goodcity::ValidationError.new(I18n.t('messages.no_private_recipient')) if is_private
    elsif managed_by?(sender) || sender_id == User.system_user.try(:id)
      # > A staff member created a message with no recipient, we default to the donor
      self.recipient_id = messageable_owner_id unless is_private
    end
  end

  def messageable_owner_id
    resolvers = {
      'Offer' => ->(obj) { obj.try(:created_by_id) },
      'OfferResponse' => ->(obj) { obj.try(:user_id) },
      'Order' => ->(obj) { obj.try(:created_by_id) },
      'Item'  => ->(obj) { obj.try(:offer).try(:created_by_id) }
    }
    resolvers[messageable_type].try(:call, messageable)
  end
end
