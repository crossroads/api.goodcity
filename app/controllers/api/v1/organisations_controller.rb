module Api::V1
  class OrganisationsController < Api::V1::ApiController
    load_and_authorize_resource :organisation, parent: false

    api :GET, '/v1/orders', "List all orders"
    def index
      records = @organisations.search(params["searchText"])
      render json: records, serializer: serializer
    end

    private
    def serializer
      Api::V1::OrganisationSerializer
    end
  end
end

