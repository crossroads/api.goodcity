class OrderTransport < ActiveRecord::Base
  include PushUpdatesMinimal

  before_save :save_timeslot_to_schedule

  belongs_to :order, inverse_of: :order_transport
  belongs_to :contact
  belongs_to :gogovan_order
  belongs_to :gogovan_transport

  validates :order_id, presence: true

  accepts_nested_attributes_for :contact

  scope :for_orders, ->(order_ids) { joins(:order).where(orders: { id: order_ids }) }

  scope :user_orders, ->(user_id) { joins(:order).where(orders: { created_by_id: user_id }) }

  # Live update rules
  after_save :push_changes
  after_destroy :push_changes
  push_targets do |record|
    [
      Channel.private_channels_for(record.order.created_by_id, BROWSE_APP),
      Channel::ORDER_FULFILMENT_CHANNEL
    ]
  end

  def pickup?
    transport_type == "self"
  end

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
