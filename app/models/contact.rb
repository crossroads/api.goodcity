class Contact < ActiveRecord::Base
  has_one :address, as: :addressable, dependent: :destroy
end
