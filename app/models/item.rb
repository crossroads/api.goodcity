class Item < ActiveRecord::Base
  include Paranoid
  include StateMachineScope
  include PushUpdates

  belongs_to :offer,     inverse_of: :items
  belongs_to :item_type, inverse_of: :items
  belongs_to :rejection_reason
  belongs_to :donor_condition
  has_many   :messages, dependent: :destroy
  has_many   :images, dependent: :destroy
  has_many   :packages, dependent: :destroy

  validates :donor_condition_id, presence: true

  scope :with_eager_load, -> {
    eager_load( [:item_type, :rejection_reason, :donor_condition, :images,
      { messages: :sender }, { packages: :package_type }
    ] )
  }

  # Workaround to set initial state fror the state_machine
  # StateMachine has Issue with rails 4.2, it does not set initial
  # state by default
  # refer - https://github.com/pluginaweek/state_machine/issues/334
  after_initialize :set_initial_state

  def set_initial_state
    self.state ||= :draft
  end

  state_machine :state, initial: :draft do
    state :rejected
    state :submitted
    state :accepted

    event :accept do
      transition [:draft, :submitted, :accepted, :rejected] => :accepted
    end

    event :reject do
      transition [:draft, :submitted, :accepted, :rejected] => :rejected
    end

    event :submit do
      transition :draft => :submitted
    end

    after_transition on: [:accept, :reject], do: :assign_reviewer
    after_transition on: :reject, do: :send_reject_message
  end

  def send_reject_message
    if rejection_comments.present? && !is_recently_messaged_reason?
      messages.create(
        is_private: false,
        body: rejection_comments,
        offer: offer,
        sender: User.current_user
      )
    end
  end

  def is_recently_messaged_reason?
    messages.last.try(:body) == rejection_comments
  end

  def update_saleable
    update(saleable: true)
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
end
