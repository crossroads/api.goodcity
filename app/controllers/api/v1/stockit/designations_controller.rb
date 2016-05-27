module Api::V1::Stockit
  class DesignationsController < Api::V1::ApiController

    before_action :eager_load_designation, only: :show
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
      records = @designations.with_eager_load.search(params['searchText']).
        latest.page(params["page"]).per(params["per_page"])
      designations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "designations").to_json
      render json: designations.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}}}"
    end

    api :GET, '/v1/designations/1', "Get a designation"
    def show
      render json: @designation, serializer: serializer
    end

    def serializer
      ::Api::V1::Stockit::DesignationSerializer
    end

    def eager_load_designation
      @designation = ::Stockit::Designation.with_eager_load.find(params[:id])
    end
  end
end
