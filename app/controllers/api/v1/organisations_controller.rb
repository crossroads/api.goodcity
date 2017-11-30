module Api::V1
  class OrganisationsController < Api::V1::ApiController
    load_and_authorize_resource :organisation, parent: false

    api :GET, '/v1/orders', "List all orders"
    def index
      @organisations = @organisations.search(params["searchText"])
      render json: @organisations, each_serializer: serializer
    end

    private
    def serializer
      Api::V1::OrganisationSerializer
    end
  end
end

