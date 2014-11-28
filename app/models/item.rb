class Item < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  belongs_to :offer,     inverse_of: :items
  belongs_to :item_type, inverse_of: :items
  belongs_to :rejection_reason
  belongs_to :donor_condition
  has_many   :messages
  has_many   :images
  has_many   :packages, dependent: :destroy

  validates :donor_condition_id, presence: true

  scope :with_eager_load, -> {
    eager_load( [:item_type, :rejection_reason, :donor_condition, :images,
      { messages: :sender }, { packages: :package_type }
    ] )
  }

  state_machine :state, initial: :draft do
    state :rejected
    state :submitted
    state :accepted

    event :accept do
      transition [:draft, :submitted] => :accepted
    end

    event :reject do
      transition [:draft, :submitted] => :rejected
    end

    event :submit do
      transition :draft => :submitted
    end

    after_transition on: [:reject, :accept], do: :update_ember_store
  end

  def self.update_saleable
    update_all(saleable: true)
  end

  def update_ember_store
    self.try(:offer).try(:update_ember_store)
  end

end
