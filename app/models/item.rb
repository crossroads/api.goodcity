class Item < ActiveRecord::Base

  belongs_to :offer,     inverse_of: :items
  belongs_to :item_type, inverse_of: :items
  belongs_to :rejection_reason
  has_many   :messages,  as: :recipient
  has_many   :images,    as: :parent, dependent: :destroy
  has_many   :packages

  state_machine :state, initial: :draft do
    state :submit # awaiting review
    state :not_needed
    state :need_detail
    state :confirmed

    event :submit do
      transition :draft => :submit
    end

    event :confirmed do
      transition [:submit, :need_detail] => :confirmed
    end

    event :need_detail do
      transition :submit => :need_detail
    end
  end

  def self.update_saleable
    update_all(saleable: true)
  end

end
