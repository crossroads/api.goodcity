class Box < ApplicationRecord
  has_many :packages
  belongs_to :pallet
end
