module Api::V1
  class PackagesLocationsController < Api::V1::ApiController
    load_and_authorize_resource :packages_location, parent: false
    before_action :eager_load_packages_locations, only: :show

    resource_description do
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :packages_locations do
      param :packages_locations, Hash, required: true do
        param :package_id, Integer, desc: "Id of package"
        param :location_id, Integer, desc: "Id of location"
        param :quantity, Integer, desc: "Quantity of orders_package"
        param :reference_to_orders_package, Integer, desc: "reference to orders_package"
      end
    end

    def show
      render json: @packages_location, serializer: serializer
    end

    def eager_load_packages_locations
      @packages_location = PackagesLocation.with_eager_load.find(params[:id])
    end

    private
    def serializer
      Api::V1::PackagesLocationSerializer
    end
  end
end
