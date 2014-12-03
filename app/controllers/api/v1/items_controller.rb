module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false

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
        param :donor_description, String, allow_nil: true, desc: "Description/Details of item given by Item-Donor"
        param :donor_condition_id, String, desc: "Describes the item's condition "<< DonorCondition.pluck(:id, :name_en).map{|x| "#{x.first} - #{x.last}"}.join("; ")
        param :state_event, Item.valid_events, allow_nil: true, desc: "Fires the state transition (if allowed) for this item. 'submit' is for when the donor has completed creating the item and will change the state from draft to submitted. Items in draft state should be hidden from offer view and if donor clicks to add an item the draft item should be loaded allowing them to continue creating the item."
        param :offer_id, String, desc: "Id of Offer to which item belongs."
        param :item_type_id, String, allow_nil: true, desc: "Not yet used"
        param :rejection_reason_id, String, desc: "A categorisation describing the reason the item was rejected "<< RejectionReason.pluck(:id, :name_en).map{|x| "#{x.first} - #{x.last}"}.join("; "), allow_nil: true
        param :reject_reason, String, allow_nil: true, desc: "Reviewer description of why the item was rejected"
        param :rejection_comments, String, allow_nil: true, desc: "Reviewer description of why the item was rejected given to Donor."
      end
    end

    api :POST, '/v1/items', "Create an item"
    param_group :item
    def create
      @item.attributes = item_params
      if @item.save
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
      if @item.update_attributes(item_params)
        render json: @item, serializer: serializer
      else
        render json: @item.errors.to_json, status: 422
      end
    end

    private

    def item_params
      params.require(:item).permit(:donor_description, :donor_condition_id,
        :state_event, :offer_id, :item_type_id, :rejection_reason_id,
        :reject_reason, :rejection_comments)
    end

    def serializer
      Api::V1::ItemSerializer
    end
  end
end
