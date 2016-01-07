module Api::V1
  class LocationsController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :create]
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
      if params[:ids].blank?
        render json: Location.cached_json
        return
      end
      @locations = @locations.with_eager_load
      @locations = @locations.find( params[:ids].split(",") ) if params[:ids].present?
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
