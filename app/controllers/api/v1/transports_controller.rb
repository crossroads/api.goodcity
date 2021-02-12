module Api
  module V1
    class TransportsController < Api::V1::ApiController

      skip_authorization_check only: :update_hook
      load_and_authorize_resource :transport_order, parent: false, except: [:update_hook]

      before_action :validate_transport_source, only: [:quote, :book]

      api :GET, '/v1/transports/providers', "List all GoodCity Tranports Options."
      def providers
        render json: TransportProvider.all.cached_json
      end

      api :POST, '/v1/transports/quote', "Get provider quote"
      param :provider, TRANSPORT_PROVIDERS, required: true, desc: "Provider selected for transport"
      param :vehicle_type, String, required: true, desc: "Transport vehicle-type"
      param :source_id, [Integer, String], required: true, desc: "Id of the source (offer/order)"
      param :source_type, String, required: true, desc: "Type of the source (offer/order)"
      param :schedule_at, String, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      def quote
        order_price = TransportService.new(transport_params.to_h).quotation
        render json: order_price
      end

      api :POST, '/v1/transports/book', "Book transport"
      param :provider, TRANSPORT_PROVIDERS, required: true, desc: "Provider selected for transport"
      param :vehicle_type, String, required: true, desc: "Transport vehicle-type"
      param :source_id, String, required: true, desc: "Id of the source (offer/order)"
      param :source_type, String, required: true, desc: "Type of the source (offer/order)"
      param :schedule_at, String, required: true, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      param :pickup_contact_name, String, desc: "Contact Person Name"
      param :pickup_contact_phone, String, desc: "Contact Person Mobile"
      param :pickup_street_address, String, required: true, desc: "Pickup Address"
      def book
        order_info = TransportService.new(transport_params.to_h).book
        render json: order_info
      end

      api :GET, '/v1/transports/:order_uuid', "Get GoodCity Tranport order details."
      def show
        order_info = TransportService.new({booking_id: params[:order_uuid], provider: transport_provider}).status
        render json: order_info
      end

      api :POST, '/v1/transports/:order_uuid/cancel', "Cancel GoodCity Tranport order."
      def cancel
        order_info = TransportService.new({booking_id: params[:order_uuid], provider: transport_provider}).cancel
        render json: order_info
      end

      api :POST, '/v1/transports/update_hook', "Webhook to update transport status"
      def update_hook
        # setup ngrok and inspect response
        # response details are not yet available from Gogox Provider
      end

      private

      def validate_transport_source
        if params['source_type'] == 'Offer'
          if !User.current_user.offers.pluck(:id).include?(params['source_id'].to_i)
            raise Goodcity::UnauthorizedError.with_text("You are not authorized to book transport for this offer.")
          end
        end

        if params['source_type'] == 'Order'
          if !User.current_user.created_orders.pluck(:id).include?(params['source_id'].to_i)
            raise Goodcity::UnauthorizedError.with_text("You are not authorized to book transport for this order.")
          end
        end
      end

      def transport_provider
        order = TransportOrder.find_by(order_uuid: params[:order_uuid])
        order.try(:transport_provider).try(:name)
      end

      def transport_params
        set_district_id unless params["district_id"].presence
        params.permit([
          "schedule_at", "district_id", "provider", "vehicle_type",
          "pickup_street_address", "pickup_contact_name", "pickup_contact_phone",
          "source_type", "source_id"
        ])
      end

      def set_district_id
        params["district_id"] = User.current_user.address.district_id
      end

    end
  end
end
