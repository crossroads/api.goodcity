module Api::V1
  class ItemTypesController < Api::V1::ApiController

    load_and_authorize_resource :item_type, parent: false

    def index
      #~ @item_types = @item_types.find( params[:ids].split(",") ) if params[:ids].present?
      #~ render json: @item_types, each_serializer: serializer

      # Trying out Surus all_json method (needs postgresql >= 9.2)
      json = ItemType
      if params[:ids].present?
        json = json.where(id: params[:ids].split(","))
      end
      json = json.all_json( columns: [:id, "name_#{I18n.locale}", :code] ).gsub('name_en', 'name')
      render text: "{ \"item_types\": #{json} }"
    end

    def show
      render json: @item_type, serializer: serializer
    end

    private

    def serializer
      Api::V1::ItemTypeSerializer
    end

  end
end
