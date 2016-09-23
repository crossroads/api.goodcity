module Api::V1

  class OrderTransportSerializer < ApplicationSerializer

    embed :ids, include: true
    attributes :id, :order_id, :scheduled_at, :timeslot, :transport_type,
      :vehicle_type

    has_one :contact, serializer: ContactSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer

  end
end
