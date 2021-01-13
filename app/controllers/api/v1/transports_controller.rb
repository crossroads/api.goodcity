module Api
  module V1
    class TransportsController < Api::V1::ApiController

      skip_authorization_check

      api :GET, '/v1/transports/providers', "List all GoodCity Tranports Options."
      def providers
        render json: TransportProvider.all.cached_json
      end

      api :POST, '/v1/transports/quote', "Get provider quote"
      param :provider, String, desc: "Provider selected for transport"
      param :vehicle_type, String, desc: "Transport vehicle-type"
      param :offer_id, String, desc: "Id of the offer"
      param :schedule_at, String, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      def quote
        order_price = TransportService.new(transport_params.to_h).quotation
        render json: order_price.to_json
      end

      api :POST, '/v1/transports/book', "Book transport"
      param :provider, String, desc: "Provider selected for transport"
      param :vehicle_type, String, desc: "Transport vehicle-type"
      param :offer_id, String, desc: "Id of the offer"
      param :schedule_at, String, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      param :pickup_contact_name, String, desc: "Contact Person Name"
      param :pickup_contact_phone, String, desc: "Contact Person Mobile"
      param :pickup_street_address, String, desc: "Pickup Address"
      def book
        order_info = TransportService.new(transport_params.to_h).book
        render json: order_info.to_json
      end

      api :GET, '/v1/transports/:id', "Get GoodCity Tranport order details."
      def show
        order_info = TransportService.new({booking_id: params[:id], provider: transport_provider}).status
        render json: order_info.to_json
      end

      api :POST, '/v1/transports/:id/cancel', "Cancel GoodCity Tranport order."
      def cancel
        order_info = TransportService.new({booking_id: params[:id], provider: transport_provider}).cancel
        render json: order_info.to_json
      end

      api :POST, '/v1/transports/update_hook', "Webhook to update transport status"
      def update_hook
        # setup ngrok and inspect response
        # response details are not yet available from Gogox Provider
      end

      private

      def transport_provider
        order = TransportOrder.find_by(order_uuid: params[:id])
        order.try(:transport_provider).try(:name)
      end

      def transport_params
        set_district_id unless params["district_id"].presence
        params.permit([
          "scheduled_at", "district_id", "offer_id", "provider", "vehicle_type",
          "pickup_street_address", "pickup_contact_name", "pickup_contact_phone"
        ])
      end

      def set_district_id
        params["district_id"] = User.current_user.address.district_id
      end

    end
  end
end
