module Api::V1
  class DesignationsController < Api::V1::ApiController

    skip_before_action :validate_token
    load_and_authorize_resource :designation, class: ::Stockit::Designation, parent: false

    resource_description do
      short 'Retrieve a list of designations, information about stock items that have been designated to a group or person.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/designations', "List all designations"
    def index
      render json: @designations.search(params['searchText']).latest.limit(30),
        each_serializer: serializer
    end

    def serializer
      Api::V1::Stockit::DesignationSerializer
    end
  end
end
