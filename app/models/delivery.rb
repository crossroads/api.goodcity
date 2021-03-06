class Delivery < ApplicationRecord
  has_paper_trail versions: { class_name: 'Version' }, meta: { related: :offer }
  include Paranoid
  include PushUpdatesForDelivery

  belongs_to :offer
  belongs_to :contact, dependent: :destroy, inverse_of: :delivery
  belongs_to :schedule, inverse_of: :deliveries
  belongs_to :gogovan_order, dependent: :destroy, inverse_of: :delivery

  accepts_nested_attributes_for :contact, :schedule

  before_destroy :push_back_offer_state
  after_save :update_offer_state
  after_save :send_updates, if: :successfully_scheduled? # PushUpdatesForDelivery
  after_save :notify_reviewers, if: :successfully_scheduled? # PushUpdatesForDelivery
  after_destroy { send_updates(:delete) unless Rails.env.test? } # PushUpdatesForDelivery

  def update_offer_state
    self.delivery_type = delivery_type.try(:titleize)
    offer.schedule if process_completed?
    true
  end

  def delete_old_associations
    ActiveRecord::Base.transaction do
      old_contact = contact
      old_ggv = gogovan_order
      update_column(:contact_id, nil)
      update_column(:gogovan_order_id, nil)
      old_contact.try(:really_destroy!)
      old_ggv.try(:really_destroy!)
      schedule && schedule.deliveries.delete(self)
    end
  end

  private

  def successfully_scheduled?
    offer.scheduled? && process_completed?
  end

  def push_back_offer_state
    offer.try(:cancel_schedule) unless offer.destroyed?
    true
  end

  def process_completed?
    (contact_id_previously_changed? && contact.present?) ||
      (delivery_type == 'Drop Off' && schedule_id_previously_changed? && schedule.present?)
  end
end
