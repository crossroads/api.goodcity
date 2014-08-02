class Item < ActiveRecord::Base

  belongs_to :offer,     inverse_of: :items
  belongs_to :item_type, inverse_of: :items
  belongs_to :rejection_reason
  belongs_to :donor_condition
  has_many   :messages,  as: :recipient
  has_many   :images,    as: :parent, dependent: :destroy
  has_many   :packages

  state_machine :state, initial: :draft do
    state :rejected
    state :pending
    state :accepted

    event :accept do
      transition [:draft, :pending] => :accepted
    end

    event :reject do
      transition [:draft, :pending] => :rejected
    end

    event :question do
      transition :draft => :pending
    end
  end

  def self.update_saleable
    update_all(saleable: true)
  end

  def set_favourite_image(image_id)
    images.favourites.map(&:remove_favourite)
    images.find_by_image_id(image_id).try(:set_favourite)
  end

end
