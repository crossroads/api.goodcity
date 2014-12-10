module Api::V1
  class ItemTypesController < Api::V1::ApiController

    load_and_authorize_resource :item_type, parent: false
    resource_description do
      short 'List, create and show item types.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :item_type do
      param :item_type, Hash, required: true do
        param :name, String, desc: "itemType name"
        param :code, String, desc: "itemType code", allow_nil: true
        param :parent_id, Integer, desc: "Parent ItemType", allow_nil: true
        param :is_item_type_node,  [true, false], desc: "Default child ItemType", allow_nil: false
      end
    end

    api :GET, '/v1/item_types', "List all item_types"
    def index
      if params[:ids].blank?
        render json: ItemType.cached_json
        return
      end
      @item_types = @item_types.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @item_types, each_serializer: serializer
    end

    api :GET, '/v1/item_types/1', "Details of item_type"
    def show
      render json: @item_type, serializer: serializer
    end

    api :POST, '/v1/item_types', "Create a item_type"
    param_group :item_type
    def create
      @item_type = ItemType.create_with(item_type_params).
        find_or_create_by(:"name_#{I18n.locale}" => item_type_params[:name])
      render json: @item_type, serializer: serializer
    end

    private

    def item_type_params
      attributes = [:name, :code, :parent_id, :is_item_type_node]
      params.require(:item_type).permit(attributes)
    end

    def serializer
      Api::V1::ItemTypeSerializer
    end

  end
end
