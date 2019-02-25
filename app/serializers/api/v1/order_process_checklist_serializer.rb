module Api::V1
  class OrderProcessChecklistSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :order_id, :process_checklist_id
  end
end
