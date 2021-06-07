class OrdersPurpose < ApplicationRecord
  belongs_to :order
  belongs_to :purpose
end
