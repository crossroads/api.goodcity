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
          param :stockit_id, String, desc: "stockit location record id"
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
        if location_record.save
          render json: @location, serializer: serializer, status: 201
        else
          render json: @location.errors.to_json, status: 422
        end
      end

      api :DELETE, "/v1/locations/1", "Delete Location"
      description "If request comes from stockit, find record by matching it with stockit_id."
      def destroy
        @location = Location.find_by(stockit_id: params[:id]) if is_stockit_request
        @location.try(:destroy)
        render json: {}
      end

      def search
        records = @locations.search(params['searchText']).
          page(params["page"]).per(params["per_page"])
        locations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "locations").to_json
        render json: locations.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}, \"search\": \"#{params['searchText']}\"}}"
      end

      def recent_locations
        @locations = Location.recently_used(User.current_user.id)
        render json: @locations, each_serializer: serializer
      end

      private

      def location_record
        @location = Location.where(stockit_id: location_params[:stockit_id]).first_or_initialize
        @location.assign_attributes(location_params)
        @location
      end

      def location_params
        params.require(:location).permit(:stockit_id, :building, :area)
      end

      def serializer
        Api::V1::LocationSerializer
      end
    end
  end
end
