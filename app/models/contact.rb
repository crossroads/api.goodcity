class Contact < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer }
  include Paranoid

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery, inverse_of: :contact

  accepts_nested_attributes_for :address

  # required by PaperTrail
  def offer
    delivery.try(:offer)
  end
end
