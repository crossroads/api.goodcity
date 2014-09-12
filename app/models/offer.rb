class Offer < ActiveRecord::Base
  include Paranoid

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  has_many :messages
  has_many :items, inverse_of: :offer, dependent: :destroy
  has_one :delivery

  scope :by_state, ->(state) { where(state: valid_state?(state) ? state : 'submitted') }

  scope :with_eager_load, -> {
    eager_load( [:created_by, { messages: :sender },
      { items: [:item_type, :rejection_reason, :donor_condition, :images,
               { messages: :sender }, { packages: :package_type }] }
    ])
  }

  state_machine :state, initial: :draft do
    state :submitted, :review_progressed, :reviewed, :scheduled

    event :submit do
      transition :draft => :submitted
    end

    event :start_review do
      transition :submitted => :review_progressed
    end

    event :finish_review do
      transition :review_progressed => :reviewed
    end

    event :schedule do
      transition [:submitted, :reviewed] => :scheduled
    end

    before_transition :on => :submit do |offer, transition|
      offer.submitted_at = Time.now
    end

    after_transition :on => :submit, :do => :review_message
  end

  def review_message
    PushOffer.new( offer: self ).notify_review
  end

  def update_saleable_items
    items.update_saleable
  end

  def self.valid_state?(state)
    valid_states.include?(state)
  end

  def self.valid_states
    state_machine.states.map {|state| state.name.to_s }
  end
end
