class OrderTransport < ActiveRecord::Base
  before_save :save_timeslot_to_schedule

  belongs_to :order, inverse_of: :order_transport
  belongs_to :contact
  belongs_to :gogovan_order
  belongs_to :gogovan_transport

  accepts_nested_attributes_for :contact

  scope :for_orders, ->(order_ids) { joins(:order).where(orders: { id: order_ids }) }

  scope :user_orders, ->(user_id) { joins(:order).where(orders: { created_by_id: user_id }) }

  def invalid_timeslot
    self.timeslot.blank? || (/^\d{1,2}(:\d{2})?(AM|PM)/ =~ self.timeslot) != 0
  end

  def save_timeslot_to_schedule
    return if invalid_timeslot || self.scheduled_at.blank?
    time = Time.parse self.timeslot.split('-').first
    self.scheduled_at = self
      .scheduled_at
      .to_datetime
      .in_time_zone
      .change(hour: time.hour, min: time.min)
      .utc
  end
end
