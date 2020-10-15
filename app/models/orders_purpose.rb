class OrdersPurpose < ApplicationRecord
  include RollbarSpecification
  belongs_to :order
  belongs_to :purpose
end
