module Api
  module V1
    class RestrictionsController < Api::V1::ApiController
      load_and_authorize_resource :restriction, parent: false

      resource_description do
        short 'List all Restriction'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/restrictions', "List all Restriction."
      def index
        render json: @restrictions, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::RestrictionSerializer
      end
    end
  end
end
