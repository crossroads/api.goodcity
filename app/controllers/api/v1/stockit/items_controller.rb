module Api::V1::Stockit
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, class: ::Stockit::Item, parent: false

    resource_description do
      short 'Retrieve a list of items, information about stock items that have been designated to a group or person.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/items', "List all items"
    def index
      records = @items.exclude_designated(params["orderId"]).
        search(params['searchText']).latest.
        page(params["page"]).per(params["per_page"])
      items = ActiveModel::ArraySerializer.new(records, each_serializer: serializer, root: "items").to_json
      render json: items.chop + ",\"meta\":{\"total_pages\": #{records.total_pages}}}"
    end

    def serializer
      ::Api::V1::Stockit::ItemSerializer
    end
  end
end
