module Api
  module V1
    class BookingTypesController < Api::V1::ApiController
      load_and_authorize_resource :booking_type, parent: false

      resource_description do
        short 'List Booking Type Options'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/booking_type', "List all Gogovan Tranports Options."
      def index
        render json: @booking_types, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::BookingTypeSerializer
      end
    end
  end
end
