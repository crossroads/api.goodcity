module Api::V1
  class CrossroadsTransportsController < Api::V1::ApiController

    load_and_authorize_resource :crossroads_transport, parent: false

    resource_description do
      short 'List Crossroads Tranports Options'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/crossroads_transports', "List all Crossroads Tranports Options."
    def index
      render json: @crossroads_transports, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::CrossroadsTransportSerializer
    end

  end
end
