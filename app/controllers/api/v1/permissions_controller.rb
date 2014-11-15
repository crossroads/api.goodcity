module Api::V1
  class PermissionsController < Api::V1::ApiController
    load_and_authorize_resource :permission, parent: false

    def index
      render json: Permission.cached_json
    end

    def show
      render json: @permission, serializer: serializer
    end

    private

    def serializer
      Api::V1::PermissionSerializer
    end
  end
end
