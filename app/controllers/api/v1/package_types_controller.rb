module Api
  module V1
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
        @package_types = @package_types.where(id: params[:ids].split(",")) if params[:ids].present?
        render json: @package_types.with_eager_load.cached_json
      end

      def stock_codes
        render json: @package_types.visible.with_eager_load
                                   .cached_json({ root: :codes })
      end

      def create
        @package_type.assign_attributes(package_type_params)
        if @package_type.save
          render json: {}, status: 201
        else
          render json: @package_type.errors, status: 422
        end
      end

      private

      def package_type_params
        params.require(:package_type).permit(:code, :name_en, :name_zh_tw, :visible_in_selects, :allow_requests, :allow_stock)
      end

      def serializer
        Api::V1::PackageTypeSerializer
      end
    end
  end
end
