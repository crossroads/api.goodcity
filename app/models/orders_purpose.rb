class OrdersPurpose < ActiveRecord::Base
  include RollbarSpecification
  belongs_to :order
  belongs_to :purpose
end
