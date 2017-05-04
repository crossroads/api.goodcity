module Api::V1
  class GogovanTransportsController < Api::V1::ApiController

    load_and_authorize_resource :gogovan_transport, parent: false

    resource_description do
      short 'List Gogovan Tranports Options'
      resource_description_errors
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
