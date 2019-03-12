module Api
  module V1
    class OrderTransportsController < Api::V1::ApiController
      load_and_authorize_resource :order_transport, parent: false

      def create
        save_and_render_object(@order_transport)
      end

      def update
        @order_transport.assign_attributes(order_transport_params)
        save_and_render_object_with_errors(@order_transport)
      end

      def index
        if params[:order_ids]
          @order_transports = @order_transports.for_orders(params[:order_ids].split(','))
        end
        render json: @order_transports, each_serializer: serializer, status: 200
      end

      private

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
