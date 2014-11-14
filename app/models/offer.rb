class Offer < ActiveRecord::Base
  include Paranoid
  include StateMachineScope
  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  belongs_to :reviewed_by, class_name: 'User', inverse_of: :reviewed_offers

  has_one :delivery
  has_many :items, inverse_of: :offer, dependent: :destroy
  has_many :items, inverse_of: :offer, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :messages
  has_many :users, through: :subscriptions

  validates :language, inclusion: { in: Proc.new { I18n.available_locales.map(&:to_s) } }, allow_nil: true

  accepts_nested_attributes_for :subscriptions

  scope :with_eager_load, -> {
    includes ( [:created_by, :reviewed_by, { delivery: [:schedule, :contact] }, { messages: :sender },
      { items: [:images, :packages, { messages: :sender }] }
    ])
  }

  scope :review_by, ->(reviewer_id){ where('reviewed_by_id = ?', reviewer_id) }

  before_create :set_language

  state_machine :state, initial: :draft do
    state :submitted, :under_review, :reviewed, :scheduled

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
      transition [:submitted, :reviewed] => :scheduled
    end

    before_transition :on => :submit do |offer, transition|
      offer.submitted_at = Time.now
    end

    before_transition :on => :start_review do |offer, transition|
      offer.reviewed_at = Time.now
    end

    after_transition :on => :submit, :do => :send_new_offer_notification
  end

  after_save :update_ember_store

  def update_saleable_items
    items.update_saleable
  end

  def subscribed_users(is_private)
    User
      .joins(subscriptions: [:offer, :message])
      .where(offers: {id: self.id}, messages: {is_private: is_private})
      .distinct
  end

  def start_review(reviewer)
    update_attributes(
      reviewed_by_id: reviewer.id,
      state_event: 'start_review')
  end

  def update_ember_store
    PushService.new.update_store(data: self, donor_channel: Channel.user(self.created_by)) unless state == "draft"
  end

  private

  def send_new_offer_notification
    text = I18n.t("notification.new_offer", name: self.created_by.full_name)
    PushService.new.send_notification(text: text, entity_type: "offer", entity: self, channel: Channel.reviewer)
  end

  # Set a default offer language if it hasn't been set already
  def set_language
    self.language = I18n.locale.to_s unless self.language.present?
  end

end
