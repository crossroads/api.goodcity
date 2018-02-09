module Api::V1
  class OrdersPurposeSerializer < ApplicationSerializer
    embed :ids, include: true
    has_one :purpose, serializer: PurposeSerializer
    attributes :id, :purpose_id, :order_id
  end
end
