class Offer < ActiveRecord::Base
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  belongs_to :reviewed_by, class_name: 'User', inverse_of: :reviewed_offers
  belongs_to :gogovan_transport
  belongs_to :crossroads_transport

  has_one  :delivery, dependent: :destroy
  has_many :items, -> { with_deleted }, inverse_of: :offer, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :users, through: :subscriptions

  validates :language, inclusion: { in: Proc.new { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  accepts_nested_attributes_for :subscriptions

  scope :with_eager_load, -> {
    includes (
      [
        :created_by, :reviewed_by,
        { delivery: [:schedule, :contact] },
        { messages: :sender },
        { items: [:images, :packages, { messages: :sender } ] }
      ]
    )
  }

  scope :review_by, ->(reviewer_id){ where('reviewed_by_id = ?', reviewer_id) }
  scope :active, -> { where("state NOT IN (?)", ["received", "closed"]) }

  scope :inactive, -> { where("deleted_at IS NOT NULL OR state IN (?)", ["received", "closed"]) }

  before_create :set_language
  after_initialize :set_initial_state

  # Workaround to set initial state fror the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :submitted, :under_review, :reviewed, :scheduled, :closed, :received

    event :submit do
      transition :draft => :submitted
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

    event :close do
      transition :under_review => :closed
    end

    event :receive do
      transition [:under_review, :reviewed, :scheduled] => :received
    end

    before_transition :on => :submit do |offer, transition|
      offer.submitted_at = Time.now
    end

    before_transition :on => :start_review do |offer, transition|
      offer.reviewed_at = Time.now
    end

    before_transition :on => [:finish_review, :close] do |offer, transition|
      offer.review_completed_at = Time.now
    end

    before_transition :on => :receive do |offer, transition|
      offer.received_at = Time.now
    end

    after_transition :on => :submit do |offer, transition|
      offer.send_thank_you_message
      offer.send_new_offer_notification
    end
  end

  def send_thank_you_message
    messages.create(body: I18n.t("offer.thank_message"), sender: User.system_user)
  end

  def update_saleable_items
    items.map(&:update_saleable)
  end

  def subscribed_users(is_private)
    User
      .joins(subscriptions: [:offer, :message])
      .where(offers: {id: self.id}, messages: {is_private: is_private})
      .distinct
  end

  def assign_reviewer(reviewer)
    update_attributes(
      reviewed_by_id: reviewer.id,
      state_event: 'start_review')
  end

  def send_new_offer_notification
    text = I18n.t("notification.new_offer", name: self.created_by.full_name)
    PushService.new.send_notification(text: text, entity_type: "offer", entity: self, channel: Channel.reviewer)
  end

  private

  # Set a default offer language if it hasn't been set already
  def set_language
    self.language = I18n.locale.to_s unless self.language.present?
  end

  #required by PusherUpdates module
  def offer
    self
  end
end
