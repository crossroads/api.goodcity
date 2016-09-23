module Api::V1

  class OrderTransportSerializer < ApplicationSerializer

    embed :ids, include: true
    attributes :id, :order_id, :scheduled_at, :timeslot, :gogovan_transport_id,
      :transport_type

    has_one :contact, serializer: ContactSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer

  end
end
