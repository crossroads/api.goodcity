class Offer < ActiveRecord::Base
  include Paranoid

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  has_many :messages, as: :recipient, dependent: :destroy
  has_many :items, inverse_of: :offer, dependent: :destroy
  has_one :delivery

  before_save :set_submit_time

  scope :by_state, ->(state) { where(state: valid_state?(state) ? state : 'submitted') }

  scope :with_eager_load, -> {
    eager_load( [:created_by, { messages: :sender },
      { items: [:item_type, :rejection_reason, :donor_condition, :images,
               { messages: :sender }, { packages: :package_type }] }
    ])
  }

  state_machine :state, initial: :draft do
    state :submitted

    event :submit do
      transition :draft => :submitted
    end
  end

  def update_saleable_items
    items.update_saleable
  end

  def set_submit_time
    self.submitted_at = Time.now if state_changed? && state == 'submitted'
  end

  def self.valid_state?(state)
    valid_states.include?(state)
  end

  def self.valid_states
    state_machine.states.map {|state| state.name.to_s }
  end
end
