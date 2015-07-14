module Api::V1
  class PackageCategoriesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :package_category, parent: false

    resource_description do
      short 'package_categories'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/package_categories', "List all Package Categories"
    def index
      if params[:ids].blank?
        render json: PackageCategory.cached_json
        return
      end
      render json: @package_categories, each_serializer: serializer
    end

    api :GET, '/v1/package_category/1', "List a package_category"
    def show
      render json: @package_category, serializer: serializer
    end

    private

    def serializer
      Api::V1::PackageCategorySerializer
    end

  end
end
