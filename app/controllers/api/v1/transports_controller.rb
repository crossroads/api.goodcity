module Api
  module V1
    class TransportsController < Api::V1::ApiController

      skip_authorization_check

      api :GET, '/v1/transports/providers', "List all GoodCity Tranports Options."
      def providers
        render json: TransportProvider.all.cached_json
      end

      api :POST, '/v1/transports/quotation', "Get provider quotation"
      param :provider, String, desc: "Provider selected for transport"
      param :transport_type, String, desc: "Transport vehicle-type"
      param :offer_id, String, desc: "Id of the offer"
      param :pickup_time, String, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      def quotation
      end

      api :POST, '/v1/transports/quotation', "Book transport"
      param :provider, String, desc: "Provider selected for transport"
      param :transport_type, String, desc: "Transport vehicle-type"
      param :offer_id, String, desc: "Id of the offer"
      param :pickup_time, String, desc: "Scheduled time for delivery"
      param :district_id, String, desc: "Id of the district"
      param :contact, Hash do
        param :name, String, desc: "Contact Person Name"
        param :mobile, String, desc: "Contact Person Mobile"
      end
      param :provider_options, Hash, desc: "Extra details for provider booking"
      def book
      end

      api :GET, '/v1/transports/:id/order_details', "Get GoodCity Tranport order details."
      def order_details
      end

      api :POST, '/v1/transports/:id/cancel_order', "Cancel GoodCity Tranport order."
      def cancel_order
      end

    end
  end
end
