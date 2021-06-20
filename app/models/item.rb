class Item < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer },
  only: %i[donor_description donor_condition_id state]
  include Paranoid
  include StateMachineScope
  include PushUpdates
  include ShareSupport

  belongs_to :offer, inverse_of: :items
  belongs_to :package_type, inverse_of: :items
  belongs_to :rejection_reason
  belongs_to :donor_condition
  has_many   :images, as: :imageable, dependent: :destroy
  has_many :messages, -> {
    where(is_private: false) if User.current_user.try(:donor?)
  }, as: :messageable, dependent: :destroy
  has_many   :packages, dependent: :destroy
  has_many   :expecting_packages, -> { where(state: 'expecting') }, class_name: "Package" # Used in Offer
  has_many   :missing_packages,   -> { where(state: 'missing') },   class_name: "Package" # Used in Offer
  has_many   :received_packages,  -> { where(state: 'received') },  class_name: "Package" # Used in Offer
  has_many   :inventory_packages, -> { where.not(inventory_number: nil) }, class_name: "Package"

  before_save :set_description

  scope :with_eager_load, -> {
    eager_load([:package_type, :rejection_reason, :donor_condition, :images,
               { messages: :sender }, { packages: :package_type }])
  }

  scope :accepted, -> { where("state = 'accepted'") }
  scope :donor_items, ->(donor_id) { joins(:offer).where(offers: { created_by_id: donor_id }) }

  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :rejected
    state :submitted
    state :accepted

    event :accept do
      transition %i[draft submitted accepted rejected] => :accepted
    end

    event :reject do
      transition %i[draft submitted accepted rejected] => :rejected
    end

    event :submit do
      transition %i[draft submitted] => :submitted
    end

    after_transition on: %i[accept reject], do: :assign_reviewer
    after_transition on: :reject, do: :send_reject_message
    after_transition on: :submit, do: :send_new_item_message
  end

  def set_description
    self.donor_description = donor_description.presence || package_notes
  end

  def package_notes
    if packages.present?
      packages.pluck(:notes).reject(&:blank?).join(" + ")
    else
      package_type.try(:name)
    end
  end

  def send_reject_message
    return unless rejection_comments.present? && !recently_messaged_reason?
    messages.create(
      is_private: false,
      body: rejection_comments,
      messageable: offer,
      sender: User.current_user
    )
  end

  def send_new_item_message
    if User.current_user.donor? && (offer.scheduled? || offer.reviewed?)
      if offer.reviewed?
        offer.re_review
        offer.clear_logistics_details
      end
      offer.send_item_add_message
    end
  end

  def recently_messaged_reason?
    messages.last.try(:body) == rejection_comments
  end

  def assign_reviewer
    offer.reviewed_by || offer.assign_reviewer(User.current_user)
  end

  def remove
    need_to_persist? ? self.destroy : self.really_destroy!
  end

  def need_to_persist?
    accepted? || rejected? || messages.present?
  end

  def not_received_packages?
    packages.received.count.zero?
  end
end
