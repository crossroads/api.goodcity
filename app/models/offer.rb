class Offer < ActiveRecord::Base
  has_paper_trail class_name: 'Version'
  include Paranoid
  include StateMachineScope
  include PushUpdates

  NOT_ACTIVE_STATES = ["received", "closed", "cancelled", "inactive"]

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  belongs_to :reviewed_by, class_name: 'User', inverse_of: :reviewed_offers
  belongs_to :closed_by, class_name: 'User'
  belongs_to :received_by, class_name: 'User'
  belongs_to :gogovan_transport
  belongs_to :crossroads_transport
  belongs_to :cancellation_reason

  has_many :items, inverse_of: :offer, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_one  :delivery, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :language, inclusion: { in: Proc.new { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  accepts_nested_attributes_for :subscriptions

  scope :with_eager_load, -> {
    includes (
      [
        :created_by, :reviewed_by, :closed_by,
        { delivery: [:schedule, :contact] },
        { messages: :sender },
        { items: [:images, :packages, { messages: :sender } ] }
      ]
    )
  }

  scope :reviewed_by, ->(reviewed_by_id){ where(reviewed_by_id: reviewed_by_id) }
  scope :created_by, ->(created_by_id){ where(created_by_id: created_by_id) }
  scope :non_draft, -> { where("state NOT IN (?)", 'draft') }
  scope :active, -> { where("state NOT IN (?)", NOT_ACTIVE_STATES) }
  scope :not_active, -> { where(state: NOT_ACTIVE_STATES) }
  scope :in_states, ->(states) { # overwrite concerns/state_machine_scope to add pseudo states
    states = [states].flatten.compact
    states.push(*Offer.not_active_states) if states.delete('not_active')
    states.push(*Offer.nondraft_states) if states.delete('nondraft')
    states.push(*Offer.active_states) if states.delete('active')
    states.push(*Offer.donor_valid_states) if states.delete('for_donor')
    where(state: states.uniq)
  }

  before_create :set_language
  after_initialize :set_initial_state

  # Workaround to set initial state fror the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    # todo rename 'reviewed' to 'awaiting_scheduling' to make it clear we only transition
    # to state when there are some accepted items
    state :submitted, :under_review, :reviewed, :scheduled, :closed, :received,
      :cancelled, :receiving, :inactive

    event :cancel do
      transition all => :cancelled, if: 'can_cancel?'
    end

    event :submit do
      transition [:draft, :inactive] => :submitted
    end

    event :start_review do
      transition :submitted => :under_review
    end

    event :finish_review do
      transition :under_review => :reviewed
    end

    event :schedule do
      transition :reviewed => :scheduled
    end

    event :cancel_schedule do
      transition :scheduled => :reviewed
    end

    event :mark_unwanted do
      transition [:under_review, :reviewed, :scheduled] => :cancelled
    end

    event :receive do
      transition [:under_review, :reviewed, :scheduled, :receiving] => :received
    end

    event :start_receiving do
      transition [:under_review, :reviewed, :scheduled] => :receiving
    end

    event :re_review do
      transition [:scheduled, :reviewed] => :under_review
    end

    event :mark_inactive do
      transition [:submitted, :under_review, :reviewed, :scheduled, :inactive] => :inactive
    end

    before_transition on: :submit do |offer, transition|
      offer.submitted_at = Time.now
    end

    before_transition on: :start_review do |offer, transition|
      offer.reviewed_at = Time.now
    end

    before_transition on: [:finish_review, :mark_unwanted] do |offer, transition|
      offer.review_completed_at = Time.now
    end

    before_transition on: [:mark_unwanted, :cancel, :receive] do |offer, transition|
      offer.closed_by = User.current_user
    end

    before_transition on: :mark_unwanted do |offer, transition|
      offer.cancelled_at = Time.now
      offer.cancellation_reason = CancellationReason.unwanted
    end

    before_transition on: :receive do |offer, transition|
      offer.received_at = Time.now
    end

    before_transition on: :cancel do |offer, transition|
      offer.cancelled_at = Time.now
      if User.current_user == offer.created_by
        offer.cancellation_reason = CancellationReason.donor_cancelled
      end
    end

    before_transition on: :start_receiving do |offer, transition|
      offer.received_by = User.current_user
      offer.start_receiving_at = Time.now
    end

    before_transition on: :mark_inactive do |offer, transition|
      offer.reviewed_by = nil
    end

    after_transition on: :submit do |offer, transition|
      offer.send_thank_you_message
      offer.send_new_offer_notification
      offer.send_new_offer_alert
    end

    after_transition on: :receive, do: :send_received_message
    after_transition on: :finish_review, do: :send_ready_for_schedule_message

    after_transition on: [:mark_unwanted, :re_review, :cancel] do |offer, transition|
      ggv_order = offer.try(:gogovan_order)
      ggv_order.try(:cancel_order) if ggv_order.try(:status) != 'cancelled'
    end

    after_transition on: :start_receiving do |offer, transition|
      ggv_order = offer.try(:gogovan_order)
      ggv_order.try(:cancel_order) if ggv_order.try(:pending?)
    end
  end

  class << self
    def donor_valid_states
      valid_states - ["cancelled"]
    end
    def not_active_states
      NOT_ACTIVE_STATES
    end
    def active_states
      valid_states - not_active_states
    end
    def nondraft_states
      active_states - ["draft"]
    end
  end

  def gogovan_order
    self.try(:delivery).try(:gogovan_order)
  end

  def can_cancel?
    gogovan_order ? gogovan_order.can_cancel? : true
  end

  def clear_logistics_details
    update_attributes(crossroads_transport_id: nil, gogovan_transport_id: nil)
  end

  def send_thank_you_message
    send_message(I18n.t("offer.thank_message"), User.system_user)
  end

  def send_ready_for_schedule_message
    send_message(I18n.t("offer.ready_for_schedule_message"), reviewed_by)
  end

  def send_received_message
    send_message(I18n.t("offer.received_message"), User.system_user)
  end

  def send_item_add_message
    text = I18n.t("offer.item_add_message", donor_name: created_by.full_name)
    messages.create(sender: User.system_user, is_private: true, body: text)
  end

  def send_message(body, user)
    messages.create(body: body, sender: user)
  end

  def update_saleable_items
    items.map(&:update_saleable)
  end

  def subscribed_users(is_private)
    Message.unscoped.joins(:subscriptions)
      .select("distinct subscriptions.user_id as user_id")
      .where(is_private: is_private, offer_id: id)
      .map(&:user_id)
  end

  def assign_reviewer(reviewer)
    update_attributes(
      reviewed_by_id: reviewer.id,
      state_event: 'start_review')
  end

  def send_new_offer_notification
    PushService.new.send_notification Channel.reviewers, true, {
      category:   'new_offer',
      message:    I18n.t("notification.new_offer", name: created_by.full_name),
      offer_id:   id,
      author_id:  created_by_id
    }
  end

  def send_new_offer_alert
    mobiles = (ENV['NEW_OFFER_ALERT_MOBILES'] || "").split(",").map(&:strip).compact
    if mobiles.any?
      User.where(mobile: mobiles).each do |user|
        TwilioService.new(user).new_offer_alert(self)
      end
    end
  end

  def send_ggv_cancel_order_message(ggv_time)
    send_message(cancel_message(ggv_time), User.system_user)
  end

  def reviewer_channel
    reviewed_by_id && "user_#{reviewed_by_id}"
  end

  def call_notify_channels
    channel_names = Channel.private(subscribed_users(true))
    if (channel_names - [reviewer_channel]).blank?
      channel_names = Channel.private(User.supervisors.pluck(:id))
    end
    channel_names << reviewer_channel
    channel_names.uniq.compact
  end

  def has_single_item?
    state != 'draft' && items.length == 1
  end

  private

  def cancel_message(time)
    text = I18n.t("offer.ggv_cancel_message", time: time, locale: "en")
    text += "<br/>"
    text += I18n.t("offer.ggv_cancel_message", time: time, locale: "zh-tw")
  end

  # Set a default offer language if it hasn't been set already
  def set_language
    self.language = I18n.locale.to_s unless self.language.present?
  end

  #required by PusherUpdates module
  def offer
    self
  end
end
