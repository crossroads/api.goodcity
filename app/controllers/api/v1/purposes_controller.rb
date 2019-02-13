module Api
  module V1
    class PurposesController < Api::V1::ApiController
      load_and_authorize_resource :purpose, parent: false

      resource_description do
        short 'List all Purpose'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/purposes', "List all Purpose."
      def index
        render json: @purposes, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::PurposeSerializer
      end
    end
  end
end
