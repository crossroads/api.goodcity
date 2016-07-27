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
      @package_types = @package_types.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @package_types.visible, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::PackageTypeSerializer
    end

  end
end
