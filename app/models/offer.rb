class Offer < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :created_by, class_name: 'User', inverse_of: :offers
  has_many :messages, as: :recipient, dependent: :destroy
  has_many :items, inverse_of: :offer, dependent: :destroy

  scope :with_eager_load, -> {
    includes( [:created_by, {messages: :sender},
               {items: [:item_type, :rejection_reason, :donor_condition, :images, {messages: :sender}, { packages: :package_type }]}
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

  # restore offer and its dependently destroyed associated records
  def recover
    restore(recursive: true)
  end

  def submitted?
    state == 'submitted'
  end

end
