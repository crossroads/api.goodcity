module Api
  module V1
    class StocktakesController < Api::V1::ApiController
      load_and_authorize_resource :stocktake, parent: false

      resource_description do
        short "List Stocktake Options"
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, "/v1/stocktakes", "List all stocktakes"
      def index
        render json: @stocktakes, each_serializer: serializer
      end

      api :GET, "/v1/stocktakes/:id", "Get a stocktake by id"
      def show
        render json: @stocktake, serializer: serializer
      end

      api :POST, "/v1/stocktakes", "Create a stocktake"
      def create
        @stocktake.created_by = current_user
        save_and_render_object_with_errors(@stocktake)
      end

      api :PUT, "/v1/stocktakes/:id/commit", "Processes a stocktake and tries to apply changes"
      def commit
        Stocktake.process_stocktake(@stocktake)
        render json: @stocktake, serializer: serializer, status: 200
      end

      api :DELETE, "/v1/stocktakes/:id", "Deletes a stocktake and all its revisions"
      def destroy
        @stocktake.destroy!
        render json: {}, status: 200
      end

      private

      def stocktake_params
        attributes = [:location_id, :name]
        { state: 'open' }.merge(
          params.require(:stocktake).permit(attributes)
        )
      end

      def serializer
        Api::V1::StocktakeSerializer
      end
    end
  end
end
