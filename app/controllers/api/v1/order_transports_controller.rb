module Api
  module V1
    class OrderTransportsController < Api::V1::ApiController
      load_and_authorize_resource :order_transport, parent: false

      def create
        save_and_render_object(@order_transport)
      end

      def update
        if @order_transport.update_attributes(order_transport_params)
          render json: @order_transport, serializer: serializer
        else
          render_errors
        end
      end

      private

      def render_errors
        render json: @order_transport.errors.to_json, status: 422
      end

      def order_transport_params
        params.require(:order_transport).permit(:order_id, :scheduled_at,
          :timeslot, :transport_type, :contact_id, :gogovan_order_id,
          :need_english, :need_cart, :need_carry, :need_over_6ft,
          :gogovan_transport_id, :remove_net,
          contact_attributes: [:name, :mobile, { address_attributes: [:district_id] }])
      end

      def serializer
        Api::V1::OrderTransportSerializer
      end
    end
  end
end
