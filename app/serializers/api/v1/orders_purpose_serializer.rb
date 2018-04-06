module Api::V1
  class OrdersPurposeSerializer < ApplicationSerializer
    embed :ids, include: true
    has_one :purpose, serializer: PurposeSerializer
    attributes :id, :purpose_id, :order_id, :designation_id

    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end
  end
end
