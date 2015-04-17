class Delivery < ActiveRecord::Base
  include Paranoid

  belongs_to :offer
  belongs_to :contact, dependent: :destroy, inverse_of: :delivery
  belongs_to :schedule, inverse_of: :deliveries
  belongs_to :gogovan_order, dependent: :destroy, inverse_of: :delivery

  accepts_nested_attributes_for :contact, :schedule

  before_save :update_offer_state
  before_destroy :push_back_offer_state
  after_save :send_updates, if: "offer.scheduled?"

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

  def send_updates
    donor   = offer.created_by
    user    = Api::V1::UserSerializer.new(User.current_user || donor)
    channel = Channel.staff + Channel.user_id(donor.id)
    data    = { item: serialized_object, sender: user, operation: "update" }
    PushService.new.send_update_store(channel, data, "offer#{offer.id}")
    true
  end

  def serialized_object
    associations = Delivery.reflections.keys.map(&:to_sym)
    Api::V1::DeliverySerializer.new(self, { exclude: associations })
  end
end
