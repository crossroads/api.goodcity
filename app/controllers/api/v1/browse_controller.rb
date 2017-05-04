module Api::V1
  class BrowseController < Api::V1::ApiController

    load_and_authorize_resource :package, parent: false
    skip_before_action :validate_token

    resource_description do
      short 'Get items list.'
      resource_description_errors
    end

    api :GET, '/v1/browse/fetch_packages', "List all packages"
    def fetch_packages
      packages = @packages.browse_inventorized.union(@packages.browse_non_inventorized)
      render json: packages, each_serializer: serializer, root: "package"
    end

    private

    def serializer
      Api::V1::BrowsePackageSerializer
    end
  end
end
