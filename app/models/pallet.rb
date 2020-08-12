class Pallet < ApplicationRecord
  has_many :packages
  has_many :boxes
end
