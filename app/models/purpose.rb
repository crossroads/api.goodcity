class Purpose < ApplicationRecord
  include RollbarSpecification
  belongs_to :order
end
