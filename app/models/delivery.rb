class Delivery < ActiveRecord::Base
  include Paranoid

  belongs_to :offer
  belongs_to :contact, dependent: :destroy
  belongs_to :schedule
  belongs_to :gogovan_order, dependent: :destroy

  before_save :update_offer_state

  def update_offer_state
    offer.schedule  if contact_id_changed? && contact.present?
    true
  end
end
