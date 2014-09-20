class Offer < ActiveRecord::Base
  include Paranoid
  include StateMachineScope

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  has_one :delivery
  has_many :items, inverse_of: :offer, dependent: :destroy

  has_many :subscriptions, dependent: :destroy
  has_many :messages, through: :subscriptions
  has_many :users, through: :subscriptions

  accepts_nested_attributes_for :subscriptions

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

end
