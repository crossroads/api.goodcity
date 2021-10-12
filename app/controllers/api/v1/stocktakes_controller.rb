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
        render(
          json: @stocktakes,
          each_serializer: serializer,
          include_packages_locations: true,
          include_revisions: bool_param(:include_revisions, true)
        )
      end

      api :GET, "/v1/stocktakes/:id", "Get a stocktake by id"
      def show
        # eager loading to optimize serializer
        @stocktake = Stocktake.with_eager_load.find(@stocktake.id)
        render(
          json: @stocktake,
          serializer: serializer,
          include_packages_locations: true,
          include_revisions: bool_param(:include_revisions, true)
        )
      end

      api :POST, "/v1/stocktakes", "Create a stocktake"
      def create
        raise Goodcity::DuplicateRecordError if Stocktake.find_by(name: stocktake_params['name']).present?

        @stocktake.created_by = current_user
        ActiveRecord::Base.transaction do
          success = @stocktake.save
          @stocktake.populate_revisions! if success

          if success
            render json: @stocktake, serializer: serializer, status: 201
          else
            render_error @stocktake.errors.full_messages.join(". ")
          end
        end
      end

      api :PUT, "/v1/stocktakes/:id/commit", "Processes a stocktake and tries to apply changes"
      def commit
        raise Goodcity::InvalidStateError.new(I18n.t('stocktakes.invalid_state')) if @stocktake.closed? || @stocktake.cancelled?

        if @stocktake.open?
          @stocktake.mark_for_processing
          StocktakeJob.perform_later(@stocktake.id)
        end

        render json: @stocktake, serializer: serializer, status: 200
      end

      api :PUT, "/v1/stocktakes/:id/cancel", "Cancels a stocktake"
      def cancel
        @stocktake.cancel if @stocktake.open?
        render json: @stocktake, serializer: serializer, status: 200
      end

      api :DELETE, "/v1/stocktakes/:id", "Deletes a stocktake and all its revisions"
      def destroy
        @stocktake.destroy!
        render json: {}, status: 200
      end

      private

      def stocktake_params
        attributes = %i[location_id name comment]
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
