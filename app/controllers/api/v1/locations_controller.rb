module Api::V1
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
        param :stockit_id, Integer, desc: "stockit location record id"
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

    private

    def serializer
      Api::V1::LocationSerializer
    end

  end
end
