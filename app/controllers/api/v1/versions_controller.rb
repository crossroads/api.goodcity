module Api::V1
  class VersionsController < Api::V1::ApiController

    load_and_authorize_resource :version, parent: false

    resource_description do
      short 'List Versions of items and related packages'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/Versions', "List Versions of items and related packages"
    def index
      render json: @versions.items_and_calls_log, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::VersionSerializer
    end

  end
end
