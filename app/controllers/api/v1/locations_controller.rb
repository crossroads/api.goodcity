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

        # The shared browse path (no params, and no params[:with_counts]) stays the cached, byte-identical
        # { id, building, area } body the legacy stock app reads.
        if params[:ids].blank? && params[:with_counts].blank?
          render json: Location.cached_json
          return
        end
        # Admin-only: eager-load :printer so printer_name isn't an N+1 (packages_count is a COUNT, not a load).
        @locations = @locations.includes(:printer) if params[:with_counts].present?
        @locations = @locations.find(params[:ids].split(",")) if params[:ids].present?
        render json: @locations, each_serializer: serializer, root: "locations"
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

      api :PUT, "/v1/locations/:id", "Rename a location"
      param_group :location
      def update
        if @location.update(location_params)
          render json: @location, serializer: serializer, status: 200
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
        admin_serializer? ? Api::V1::LocationAdminSerializer : Api::V1::LocationSerializer
      end

      # The stock-count / printer attributes are computed only for the Locations admin screen's own requests:
      # the #update action (rename), and #index when the explicit with_counts param is sent. Every other path
      # (#create, the shared browse/search/recently-used GET) keeps the lean { id, building, area } body.
      def admin_serializer?
        action_name == "update" || (action_name == "index" && params[:with_counts].present?)
      end
    end
  end
end
