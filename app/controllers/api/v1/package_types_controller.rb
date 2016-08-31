module Api::V1
  class PackageTypesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :package_type, parent: false

    resource_description do
      short "Get package types."
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 500, "Internal Server Error"
    end

    api :GET, "/v1/package_types", "get all package_types"
    def index
      return stock_codes if params['stock'].present?
      @package_types = @package_types.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @package_types.visible, each_serializer: serializer
    end

    def stock_codes
      render json: @package_types.visible, each_serializer: serializer, root: :codes
    end

    def create
      fetch_package_type.assign_attributes(package_type_params)
      if @package_type.save
        render json: {}, status: 201
      else
        render json: @package_type.errors.to_json, status: 422
      end
    end

    private

    def package_type_params
      params.require(:package_type).permit(:stockit_id)
    end

    def serializer
      Api::V1::PackageTypeSerializer
    end

    def fetch_package_type
      values = params["package_type"]
      @package_type = PackageType.find_by(stockit_id: values["stockit_id"]) || @package_type
      @package_type.location_id = values["location_id"].present? ? fetch_location_id(values["location_id"]) : nil
      @package_type
    end

    def fetch_location_id(stockit_location_id)
      Location.find_by(stockit_id: stockit_location_id).try(:id)
    end

  end
end
