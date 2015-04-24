class Contact < ActiveRecord::Base
  include Paranoid

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery, inverse_of: :contact

  accepts_nested_attributes_for :address
end
