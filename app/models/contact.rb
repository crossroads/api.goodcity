class Contact < ActiveRecord::Base
  include Paranoid

  has_one :address, as: :addressable, dependent: :destroy
  has_one :delivery
end
