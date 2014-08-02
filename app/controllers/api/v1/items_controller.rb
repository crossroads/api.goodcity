module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false

    def create
      @item.attributes = item_params
      if @item.save
        store_images
        render json: @item, serializer: serializer, status: 201
      else
        render json: @item.errors.to_json, status: 500
      end
    end

    # /items?ids=1,2,3,4
    def index
      @items = @items.find(params[:ids].split(",")) if params[:ids].present?
      render json: @items, each_serializer: serializer
    end

    def show
      render json: @item, serializer: serializer
    end

    def destroy
      @item.destroy
      render json: {}
    end

    def update
      @item.update_attributes(item_params)
      store_images
      render json: @item, serializer: serializer, status: 201
    end

    private

    def item_params
      params.require(:item).permit(:donor_description, :donor_condition_id,
        :state, :offer_id, :item_type_id, :rejection_reason_id,
        :rejection_other_reason)
    end

    def serializer
      Api::V1::ItemSerializer
    end

    def store_images
      image_ids = params[:item][:image_identifiers].split(',')
      # assign newly added images
      image_ids.each do |img|
        @item.images.where(image_id: img).first_or_create
      end

      # remove deleted image records
      (@item.image_identifiers - image_ids).each do |img|
        @item.images.where(image_id: img).first.try(:destroy)
      end

      # set favourite image
      @item.set_favourite_image(params[:item][:favourite_image])
    end

  end
end
