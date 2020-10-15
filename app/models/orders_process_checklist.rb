class OrdersProcessChecklist < ApplicationRecord
  belongs_to :order, inverse_of: :orders_process_checklists
  belongs_to :process_checklist

  scope :by_order, -> (order_id) { where(order_id: order_id) }
end
