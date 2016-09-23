class OrderTransport < ActiveRecord::Base

  belongs_to :order, inverse_of: :order_transport
  belongs_to :contact
  belongs_to :gogovan_order

  scope :user_orders, ->(user_id) { joins(:order).where(orders: {created_by_id: user_id}) }

end
