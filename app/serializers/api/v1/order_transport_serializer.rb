module Api::V1
  class OrderTransportSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :order_id, :scheduled_at, :timeslot, :gogovan_transport_id,
      :transport_type, :need_english, :need_cart, :need_carry, :designation_id,
      :need_over_6ft, :remove_net, :need_over_six_ft, :booking_type_id

    has_one :contact, serializer: ContactSerializer
    has_one :gogovan_order, serializer: GogovanOrderSerializer
    has_one :booking_type, serializer: BookingTypeSerializer


    def need_over_six_ft
      object.need_over_6ft
    end

    def need_over_six_ft__sql
      "need_over_6ft"
    end

    def designation_id
      object.order_id
    end

    def designation_id__sql
      "order_id"
    end
  end
end
