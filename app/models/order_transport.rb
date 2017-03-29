class OrderTransport < ApplicationRecord

  belongs_to :order, inverse_of: :order_transport
  belongs_to :contact
  belongs_to :gogovan_order
  belongs_to :gogovan_transport

  accepts_nested_attributes_for :contact

  scope :user_orders, ->(user_id) { joins(:order).where(orders: {created_by_id: user_id}) }

end
