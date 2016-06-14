class Delivery < ActiveRecord::Base
  has_paper_trail class_name: 'Version', meta: { related: :offer }
  include Paranoid

  belongs_to :offer
  belongs_to :contact, dependent: :destroy, inverse_of: :delivery
  belongs_to :schedule, inverse_of: :deliveries
  belongs_to :gogovan_order, dependent: :destroy, inverse_of: :delivery

  accepts_nested_attributes_for :contact, :schedule

  before_save :update_offer_state
  before_destroy :push_back_offer_state
  after_save :send_updates, if: :successfully_scheduled?
  after_save :notify_reviewers, if: :successfully_scheduled?
  after_destroy {send_updates :delete unless Rails.env.test? }

  def update_offer_state
    self.delivery_type = delivery_type.try(:titleize)
    offer.schedule if process_completed?
    true
  end

  def delete_old_associations
    contact.try(:really_destroy!)
    gogovan_order.try(:really_destroy!)
    update_column(:contact_id, nil)
    update_column(:gogovan_order_id, nil)
    schedule && schedule.deliveries.delete(self)
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
    (contact_id_changed? && contact.present?) ||
    (delivery_type == 'Drop Off' && schedule_id_changed? && schedule.present?)
  end

  def send_updates(operation = nil)
    donor   = offer.created_by
    records = [gogovan_order, contact.try(:address), contact, schedule, self]

    records.compact.each do |record|
      operation ||= (self.class == 'Delivery' ? "update" : "create")
      data = { item: serialized_object(record), sender: serialized_user(donor), operation: operation }
      push_updates(donor, data)
    end
    true
  end

  def push_updates(donor, data)
    PushService.new.send_update_store(Channel.staff, true, data)
    PushService.new.send_update_store(Channel.private(donor), false, data)
  end

  def serialized_user(donor)
    Api::V1::UserSerializer.new(User.current_user || donor)
  end

  def serialized_object(record)
    associations = record.class.reflections.keys.map(&:to_sym)
    "Api::V1::#{record.class}Serializer".constantize.new(record, { exclude: associations })
  end

  def notify_reviewers
    PushService.new.send_notification Channel.reviewer, true, {
      category: 'offer_delivery',
      message:   delivery_notify_message,
      offer_id:  offer.id,
      author_id: offer.created_by_id
    }
  end

  def delivery_notify_message
    formatted_date = schedule.scheduled_at.strftime("%a #{schedule.scheduled_at.day.ordinalize} %b %Y")
    I18n.t("delivery.#{delivery_type.downcase.tr(" ","_")}_message",
      name: offer.created_by.full_name,
      time: schedule.slot_name,
      date: formatted_date)
  end
end
