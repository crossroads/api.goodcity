module Api
  module V1
    class PrintersController < Api::V1::ApiController
      load_and_authorize_resource :printer, parent: false

      resource_description do
        short "List Printer Options"
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, "/v1/printer", "List all active printers"

      def index
        render json: @printers.active, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::PrinterSerializer
      end
    end
  end
end
