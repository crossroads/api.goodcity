module Api
  module V1
    class TerritoriesController < Api::V1::ApiController
      skip_before_action :validate_token, only: [:index, :show]
      load_and_authorize_resource :territory, parent: false

      resource_description do
        short 'Hong Kong is divided into territories which is further subdivided into districts.'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/territories', "List all territories"
      def index
        if params[:ids].blank?
          render json: Territory.cached_json
          return
        end
        @territories = @territories.with_eager_load
        @territories = @territories.where(id: params["ids"].split(",").flatten) if params["ids"].present?
        render json: @territories, each_serializer: serializer
      end

      api :GET, '/v1/territory/1', "List a territory"
      def show
        render json: @territory, serializer: serializer
      end

      private

      def serializer
        Api::V1::TerritorySerializer
      end
    end
  end
end
