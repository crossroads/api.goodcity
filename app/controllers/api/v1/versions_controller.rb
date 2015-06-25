module Api::V1
  class VersionsController < Api::V1::ApiController

    load_and_authorize_resource :version, parent: false

    def index
      render json: @versions.items_log, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::VersionSerializer
    end

  end
end
