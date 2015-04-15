class Delivery < ActiveRecord::Base
  include Paranoid
  include PushUpdates

  belongs_to :offer
  belongs_to :contact, dependent: :destroy
  belongs_to :schedule
  belongs_to :gogovan_order, dependent: :destroy

  accepts_nested_attributes_for :contact, :schedule

  before_save :update_offer_state
  before_destroy :push_back_offer_state

  def update_offer_state
    self.delivery_type = self.delivery_type.titleize
    offer.schedule if process_completed?
    true
  end

  private

  def push_back_offer_state
    offer.try(:cancel_schedule)
    true
  end

  def process_completed?
    (contact_id_changed? && contact.present?) ||
    (delivery_type == 'Drop Off' && schedule_id_changed? && schedule.present?)
  end
end
