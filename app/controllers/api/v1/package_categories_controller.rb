module Api::V1
  class PackageCategoriesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :package_category, parent: false

    resource_description do
      short 'package_categories'
      resource_description_errors
    end

    api :GET, '/v1/package_categories', "List all Package Categories"
    def index
      if params[:ids].blank?
        render json: PackageCategory.cached_json
        return
      end
      render json: @package_categories, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::PackageCategorySerializer
    end

  end
end
