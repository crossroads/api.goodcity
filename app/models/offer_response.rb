class OfferResponse < ApplicationRecord
  validates :user_id, presence: true,on: :create
  validates :offer_id, presence: true,on: :create

  belongs_to :user
  belongs_to :offer

  has_many :messages, as: :messageable, dependent: :destroy
end
