module Api::V1
  class GogovanTransportTypesController < Api::V1::ApiController

    skip_before_action :validate_token, only: :index
    skip_authorization_check only: :index

    resource_description do
      short 'List Gogovan Tranports Options'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/gogovan_transport_types', "List all Gogovan Tranports Options."
    def index
      transport_options = YAML.load_file("#{Rails.root}/db/gogovan_transports.yml")
      render json: { gogovan_transport_types: transport_options.values }.to_json
    end

  end
end
