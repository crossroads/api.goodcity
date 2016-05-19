module Api::V1
  class DesignationsController < Api::V1::ApiController

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
      records = @designations.search(params['searchText']).latest.
        page(params["page"]).per(params["per_page"])
      designations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "designations").to_json
      render json: designations.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}}}"
    end

    def serializer
      ::Api::V1::Stockit::DesignationSerializer
    end
  end
end
