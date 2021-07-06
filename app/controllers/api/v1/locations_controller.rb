module Api
  module V1
    class LocationsController < Api::V1::ApiController
      load_and_authorize_resource :location, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :location do
        param :location, Hash, required: true do
          param :building, String, desc: "Name of building"
          param :area, String, desc: "Name of area"
        end
      end

      api :GET, '/v1/locations', "List all locations"
      param :ids, Array, of: Integer, desc: "Filter by location ids e.g. ids = [1,2,3,4]"
      def index
        return search if params['searchText'].present?
        return recent_locations if params['recently_used'].present?

        if params[:ids].blank?
          render json: Location.cached_json
          return
        end
        @locations = @locations.with_eager_load
        @locations = @locations.find(params[:ids].split(",")) if params[:ids].present?
        render json: @locations, each_serializer: serializer
      end

      api :POST, "/v1/locations", "Create or Update a location"
      param_group :location
      def create
        @location.assign_attributes(location_params)
        if @location.save
          render json: @location, serializer: serializer, status: 201
        else
          render json: @location.errors, status: 422
        end
      end

      api :DELETE, "/v1/locations/1", "Delete Location"
      def destroy
        @location.try(:destroy)
        render json: {}
      end

      def search
        records = @locations.search(params['searchText'])
                            .page(params["page"])
                            .per(params["per_page"])
        locations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "locations").as_json
        render json: { meta: { total_pages: records.total_pages, search: params['searchText'] } }.merge(locations)
      end

      def recent_locations
        @locations = Location.recently_used(User.current_user.id)
        render json: @locations, each_serializer: serializer
      end

      private

      def location_params
        params.require(:location).permit(:building, :area)
      end

      def serializer
        Api::V1::LocationSerializer
      end
    end
  end
end
