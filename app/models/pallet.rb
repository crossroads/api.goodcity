class Pallet < ActiveRecord::Base
  has_many :packages
  has_many :boxes
end
