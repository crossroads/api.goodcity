module Api::V1
  class GogovanTransportsController < Api::V1::ApiController

    load_and_authorize_resource :gogovan_transport, parent: false

    resource_description do
      short 'List Gogovan Tranports Options'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/gogovan_transports', "List all Gogovan Tranports Options."
    def index
      render json: @gogovan_transports, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::GogovanTransportSerializer
    end

  end
end
