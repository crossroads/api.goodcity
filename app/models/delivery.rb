class Delivery < ActiveRecord::Base
  belongs_to :offer
  belongs_to :contact
  belongs_to :schedule
  belongs_to :gogovan_order

  before_save :update_offer_state

  def update_offer_state
    offer.schedule  if contact_id_changed? && contact.present?
    true
  end
end
