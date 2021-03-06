module Api::V1
  class OrderTransportSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :order_id, :scheduled_at, :timeslot, :gogovan_transport_id,
      :transport_type, :need_english, :need_cart, :need_carry, :designation_id,
      :need_over_6ft, :remove_net, :need_over_six_ft

    has_one :contact, serializer: ContactSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer

    def need_over_six_ft
      object.need_over_6ft
    end

    def designation_id
      object.order_id
    end
  end
end
