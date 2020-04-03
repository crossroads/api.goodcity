module Api::V1
  class OrdersProcessChecklistsSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :designation_id, :process_checklist_id

    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end
  end
end
