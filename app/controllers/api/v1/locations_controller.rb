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

      def_param_group :location_update do
        param :location, Hash, required: true do
          param :building, String, desc: "Name of building"
          param :area, String, desc: "Name of area"
          param :retired, :boolean, desc: <<~DESC
            Retire (true) or unretire (false) the location. A retired location stays on every record that points
            at it, and plain GET /locations still lists it; GET /locations?exclude_retired=true leaves it out.
            Sets or clears retired_at; retiring an already-retired location keeps its stamp.
          DESC
        end
      end

      api :GET, '/v1/locations', "List all locations"
      param :ids, Array, of: Integer, desc: "Filter by location ids e.g. ids = [1,2,3,4]"
      param :exclude_retired, String, desc: <<~DESC
        'true' leaves retired locations out of the plain list, the searchText search and the recently_used list.
        The rows keep the same { id, building, area } shape. Without it, every response is unchanged and lists
        retired locations too. The plain list with this param is never cached.
      DESC
      param :with_counts, String, desc: <<~DESC
        Locations admin screen only (needs a token). Every location, retired ones included, with
        packages_count, printer_name, retired_at and in_use (a foreign key still points at it, so DELETE would
        answer 409).
      DESC
      def index
        return search if params['searchText'].present?
        return recent_locations if params['recently_used'].present?

        # The shared browse path (no params, and no params[:with_counts]) stays the cached, byte-identical
        # { id, building, area } body the legacy stock app reads.
        if params[:ids].blank? && params[:with_counts].blank?
          return render json: not_retired_json if exclude_retired?

          render json: Location.cached_json
          return
        end
        @locations = @locations.not_retired if exclude_retired?
        # Admin-only: eager-load :printer so printer_name isn't an N+1 (packages_count is a COUNT, not a load).
        @locations = @locations.includes(:printer) if params[:with_counts].present?
        @locations = @locations.find(params[:ids].split(",")) if params[:ids].present?
        options = admin_serializer? ? { in_use_ids: Location.in_use_ids } : {}
        render json: @locations, each_serializer: serializer, root: "locations", **options
      end

      api :POST, "/v1/locations", "Create or Update a location"
      param_group :location
      def create
        @location.assign_attributes(location_params)
        if @location.save
          render json: @location, serializer: serializer, root: "location", status: 201
        else
          render json: @location.errors, status: 422
        end
      end

      api :PUT, "/v1/locations/:id", "Rename, retire or unretire a location"
      api :PATCH, "/v1/locations/:id", "Rename, retire or unretire a location"
      param_group :location_update
      def update
        if @location.update(location_update_params)
          render json: @location, serializer: serializer, root: "location", status: 200
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
        scope = exclude_retired? ? @locations.not_retired : @locations
        records = scope.search(params['searchText'])
                            .page(params["page"])
                            .per(params["per_page"])
        locations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "locations").as_json
        render json: { meta: { total_pages: records.total_pages, search: params['searchText'] } }.merge(locations)
      end

      def recent_locations
        @locations = Location.recently_used(User.current_user.id)
        @locations = @locations.reject(&:retired?) if exclude_retired?
        render json: @locations, each_serializer: serializer
      end

      private

      def location_params
        params.require(:location).permit(:building, :area)
      end

      # Only the admin rename/retire path takes `retired`; POST /locations is the shared create and stays as it was.
      def location_update_params
        params.require(:location).permit(:building, :area, :retired)
      end

      def exclude_retired?
        params[:exclude_retired].to_s == "true"
      end

      # GET /locations?exclude_retired=true: the shared lean rows minus retired ones. Deliberately NOT cached, so it
      # never reads or writes the Location.cached_json key the legacy apps' plain list lives under.
      def not_retired_json
        ActiveModel::ArraySerializer.new(
          Location.not_retired.order(:id),
          each_serializer: Api::V1::LocationSerializer,
          root: "locations"
        ).as_json
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
