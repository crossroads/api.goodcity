module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false

    # /items?ids=1,2,3,4
    def index
      if params[:ids].present?
        @items = @items.find( params[:ids].split(",") )
      end
      render json: @items, each_serializer: serializer
    end

    def show
      render json: @item, serializer: serializer
    end

    private

    def serializer
      Api::V1::ItemSerializer
    end

  end
end
