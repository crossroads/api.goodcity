class Delivery < ActiveRecord::Base
  belongs_to :offer
  belongs_to :contact
  belongs_to :schedule

  before_save :update_offer_state

  def update_offer_state
    offer.schedule  if contact_id_changed? && contact.present?
  end
end
