module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :offer
    load_and_authorize_resource :item, through: :offer, shallow: true

    resource_description do
      short 'List, create, update and delete items.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :item do
      param :item, Hash, required: true do
        param :donor_description, String, desc: "Description/Details of item given by Item-Donor"
        param :donor_condition_id, String, desc: "Describes the item's condition "<< DonorCondition.pluck(:id, :name_en).map{|x| "#{x.first} - #{x.last}"}.join("; ")
        param :state_event, Item.valid_events, desc: "Fires the state transition (if allowed) for this item."
        param :offer_id, String, desc: "Id of Offer to which item belongs."
        param :item_type_id, String, allow_nil: true, desc: "Not yet used"
        param :rejection_reason_id, String, desc: "A categorisation describing the reason the item was rejected "<< RejectionReason.pluck(:id, :name_en).map{|x| "#{x.first} - #{x.last}"}.join("; "), allow_nil: true
        param :rejection_other_reason, String, allow_nil: true, desc: "Reviewer description of why the item was rejected"
        param :image_identifiers, String, desc: "Comma seperated list of image-ids uploaded to Cloudinary"
        param :favourite_image, String, desc: "An existing image-id that will become the default image for this item"
      end
    end

    api :POST, '/v1/items', "Create an item"
    param_group :item
    def create
      @item.attributes = item_params
      if @item.save
        store_images
        render json: @item, serializer: serializer, status: 201
      else
        render json: @item.errors.to_json, status: 422
      end
    end

    api :GET, '/v1/items', "List all items"
    param :ids, Array, of: Integer, desc: "Filter by item ids e.g. ids = [1,2,3,4]"
    def index
      @items = @items.with_eager_load # this maintains security
      @items = @items.find(params[:ids].split(",")) if params[:ids].present?
      render json: @items, each_serializer: serializer
    end

    api :GET, '/v1/offers/:offer_id/items', "List all the items of an offer"
    def index_by_offer
      @offer = Offer.find(params[:offer_id])
      @items = @items.where(offer: @offer).with_eager_load
      render json: @items, each_serializer: serializer
    end

    api :GET, '/v1/item/1', "List an item"
    def show
      render json: @item, serializer: serializer
    end

    api :DELETE, '/v1/items/1', "Delete an item"
    description "If this item's offer is in draft state it will be destroyed. Any other state and it will be marked as deleted but remain recoverable."
    def destroy
      @item.offer.draft? ? @item.really_destroy! : @item.destroy
      render json: {}
    end

    api :PUT, '/v1/items/1', "Update an item"
    param_group :item
    def update
      @item.update_attributes(item_params)
      store_images
      render json: @item, serializer: serializer, status: 200
    end

    private

    def item_params
      params.require(:item).permit(:donor_description, :donor_condition_id,
        :state_event, :offer_id, :item_type_id, :rejection_reason_id,
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
      (@item.images.image_identifiers - image_ids).each do |img|
        @item.images.where(image_id: img).first.try(:destroy)
      end

      # set favourite image
      @item.set_favourite_image(params[:item][:favourite_image])
    end

  end
end
