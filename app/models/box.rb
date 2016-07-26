class Box < ActiveRecord::Base
  has_many :packages
  belongs_to :pallet
end
