class OfferResponse < ApplicationRecord
  belongs_to :user
  belongs_to :offer

  has_many :messages, as: :messageable, dependent: :destroy
end
