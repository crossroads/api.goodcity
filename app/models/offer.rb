class Offer < ActiveRecord::Base
  include Paranoid
  include StateMachineScope
  MESSAGE_FROM_DONOR = "I have made an offer."
  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  belongs_to :reviewed_by, class_name: 'User', inverse_of: :reviewed_offers

  has_one :delivery
  has_many :items, inverse_of: :offer, dependent: :destroy
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

    after_transition :on => :submit, :do => :review_message
  end

  def review_message
    PushOffer.new( offer: self ).notify_review
    Message.on_offer_submittion({
           body: MESSAGE_FROM_DONOR,
           sender_id: self.created_by_id,
           is_private: false,
           offer_id: self.id
      })
  end

  def update_saleable_items
    items.update_saleable
  end
end
