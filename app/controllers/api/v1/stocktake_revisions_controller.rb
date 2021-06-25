module Api
  module V1
    class StocktakeRevisionsController < Api::V1::ApiController
      load_and_authorize_resource :stocktake_revision, parent: false

      resource_description do
        short "Stocktake Revisions"
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :POST, "/v1/stocktake_revisions", "Create a stocktake revision"
      def create
        stocktake = Stocktake.find(stocktake_revision_params['stocktake_id'])
        exists = StocktakeRevision.find_by(stocktake: stocktake, package_id: stocktake_revision_params['package_id'])

        raise Goodcity::DuplicateRecordError if exists.present?

        @stocktake_revision.created_by = current_user
        save_and_render_object_with_errors(@stocktake_revision)
      end

      api :PUT, "/v1/stocktakes/:id", "Updates a revision"
      def update
        @stocktake_revision.assign_attributes(stocktake_revision_params)
        save_and_render_object_with_errors(@stocktake_revision)
      end

      api :DELETE, "/v1/stocktakes/:id", "Deletes a revision"
      def destroy
        @stocktake_revision.destroy!
        render json: {}, status: 200
      end

      private

      def default_params
        { state: 'pending', dirty: false }
      end

      def stocktake_revision_params
        attributes = [:quantity, :package_id, :stocktake_id, :state, :dirty]
        default_params.merge(
          params.require(:stocktake_revision).permit(attributes)
        )
      end

      def serializer
        Api::V1::StocktakeRevisionSerializer
      end
    end
  end
end
