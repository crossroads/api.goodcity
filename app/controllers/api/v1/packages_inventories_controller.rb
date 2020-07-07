module Api
  module V1
    class PackagesInventoriesController < Api::V1::ApiController
      load_and_authorize_resource :packages_inventory, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/packages_inventories', "List all packages_inventories"
      def index
        raise Goodcity::MissingParamError.new("package_id") unless params["package_id"]
        packages_inventories = @packages_inventories.for_package(params["package_id"]).page(page).per(per_page).order('id')
        meta = {
          total_pages: packages_inventories.total_pages,
          total_count: packages_inventories.size
        }
        render json: { meta: meta }.merge(
            serialized_packages_inventories(packages_inventories)
        )
      end

      private

      def serializer
        Api::V1::PackageActionsSerializer
      end

      def serialized_packages_inventories(packages_inventories)
        ActiveModel::ArraySerializer.new(
          packages_inventories,
          each_serializer: serializer,
          root: "item_actions"
        ).as_json
      end
    end
  end
end