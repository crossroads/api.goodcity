module Api::V1
  class CrossroadsTransportTypesController < Api::V1::ApiController

    skip_before_action :validate_token, only: :index
    skip_authorization_check only: :index

    resource_description do
      short 'List Crossroads Tranports Options'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/crossroads_transport_types', "List all Crossroads Tranports Options."
    def index
      transport_options = YAML.load_file("#{Rails.root}/db/crossroads_transports.yml")
      render json: { crossroads_transport_types: transport_options.values }.to_json
    end

  end
end
