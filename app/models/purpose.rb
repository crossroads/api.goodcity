class Purpose < ActiveRecord::Base
  include RollbarSpecification
  belongs_to :order
end
