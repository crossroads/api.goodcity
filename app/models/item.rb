class Item < ActiveRecord::Base
  include Paranoid
  include StateMachineScope
  include PushUpdates

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
      transition [:draft, :submitted, :accepted, :rejected] => :accepted
    end

    event :reject do
      transition [:draft, :submitted, :accepted, :rejected] => :rejected
    end

    event :submit do
      transition :draft => :submitted
    end
  end

  def self.update_saleable
    update_all(saleable: true)
  end

  private

  #required by PusherUpdates module
  def donor_user_id
    offer.created_by_id
  end
end
