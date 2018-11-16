class OrderTransport < ActiveRecord::Base
  belongs_to :order, inverse_of: :order_transport
  belongs_to :contact
  belongs_to :gogovan_order
  belongs_to :gogovan_transport
  belongs_to :booking_type

  accepts_nested_attributes_for :contact

  scope :for_orders, ->(order_ids) { joins(:order).where(orders: { id: order_ids }) }

  scope :user_orders, ->(user_id) { joins(:order).where(orders: { created_by_id: user_id }) }
end
