module Api::V1
  class CrossroadsTransportsController < Api::V1::ApiController

    load_and_authorize_resource :crossroads_transport, parent: false

    resource_description do
      short 'List Crossroads Tranports Options'
      resource_description_errors
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
