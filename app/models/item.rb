class Item < ActiveRecord::Base

  belongs_to :offer,     inverse_of: :items
  belongs_to :item_type, inverse_of: :items
  belongs_to :rejection_reason
  has_many   :messages,  as: :recipient
  has_many   :images,    as: :parent, dependent: :destroy
  has_many   :packages

  def self.update_saleable
    update_all(saleable: true)
  end

end
