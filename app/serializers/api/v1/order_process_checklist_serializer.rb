module Api::V1
  class OrderProcessChecklistSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :order_id, :process_checklist_id, :designation_id
    
    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end
  end
end
