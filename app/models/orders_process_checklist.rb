class OrdersProcessChecklist < ActiveRecord::Base
  belongs_to :order, inverse_of: :orders_process_checklists
  belongs_to :process_checklist
end
