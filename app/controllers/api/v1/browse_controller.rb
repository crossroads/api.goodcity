module Api::V1
  class BrowseController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false
    skip_before_action :validate_token

    resource_description do
      short 'Get items list.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/browse/fetch_items', "List all items"
    def fetch_items
      render json: @items.accepted, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::ItemSerializer
    end
  end
end
