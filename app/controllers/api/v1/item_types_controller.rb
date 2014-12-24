module Api::V1
  class ItemTypesController < Api::V1::ApiController

    load_and_authorize_resource :item_type, parent: false

    resource_description do
      short 'Get item types.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/item_types', "get all item_types"
    def index
      if params[:ids].blank?
        render json: ItemType.cached_json
        return
      end
      @item_types = @item_types.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @item_types, each_serializer: serializer
    end

    private

    def serializer
      Api::V1::ItemTypeSerializer
    end

  end
end
