class StripePayment < ApplicationRecord
  belongs_to :source, polymorphic: true
end
