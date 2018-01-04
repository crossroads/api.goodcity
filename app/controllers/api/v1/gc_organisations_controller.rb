module Api::V1
  class GcOrganisationsController < Api::V1::ApiController
    load_and_authorize_resource :organisation, parent: false

    resource_description do
      short "list, show organisations"
      formats ["json"]
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/organisations', "List all organisations"
    def index
      records = @organisations.search(params["searchText"]).page(params["page"]).per(params["per_page"])
      @organisations = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "gc_organisations").to_json
      render json: @organisations.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}, \"search\": \"#{params['searchText']}\"}}"
    end

    api :GET, '/v1/organisations/1', "Details of a package"
    def show
      @organisation =  Api::V1::OrganisationSerializer.new(@organisation, root: "gc_organisations")
      render json: @organisation
    end

    private
    def serializer
      Api::V1::OrganisationSerializer
    end
  end
end
