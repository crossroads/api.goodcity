module Api::V1
  class ItemsController < Api::V1::ApiController

    load_and_authorize_resource :item, parent: false

    resource_description do
      short 'Get, create, update and delete items.'
      description <<-EOS
        == Item states
        [link:/doc/item_state.png]
      EOS
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :item do
      param :item, Hash, required: true do
        param :donor_description, String, allow_nil: true, desc: "Description/Details of item given by Item-Donor"
        param :donor_condition_id, String, desc: "Describes the item's condition "<< DonorCondition.pluck(:id, :name_en).map{|x| "#{x.first} - #{x.last}"}.join("; "), allow_nil: true
        param :state_event, Item.valid_events, allow_nil: true, desc: "Fires the state transition (if allowed) for this item. 'submit' is for when the donor has completed creating the item and will change the state from draft to submitted. Items in draft state should be hidden from offer view and if donor clicks to add an item the draft item should be loaded allowing them to continue creating the item."
        param :offer_id, String, desc: "Id of Offer to which item belongs."
        param :package_type_id, String, allow_nil: true, desc: "Not yet used"
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

    api :GET, '/v1/item/1', "Get an item"
    def show
      render json: @item, serializer: serializer
    end

    api :DELETE, '/v1/items/1', "Delete an item"
    description "If this item's offer is in draft state it will be destroyed. Any other state and it will be marked as deleted but remain recoverable."
    def destroy
      offer = @item.offer
      return single_item_error if offer.has_single_item?
      @item.remove
      update_offer_state(offer)
      render json: {}
    end

    api :PUT, '/v1/items/1', "Update an item"
    param_group :item
    def update
      offer = @item.offer

      # if rejecting last accepted item but gogovan is booked return error
      if rejecting_last_item_having_confirmed_ggv(offer)
        return render_require_ggv_cancel_error
      end

      if @item.update_attributes(item_params)
        update_offer_state(offer)
        render json: @item, serializer: serializer
      else
        render json: @item.errors.to_json, status: 422
      end
    end

    def designate_stockit_item_set
      @item.designate_set_to_stockit_order(params[:package])
      render json: @item, serializer: stockit_serializer
    end

    def dispatch_stockit_item_set
      @item.dispatch_set_to_stockit_order
      render json: @item, serializer: stockit_serializer
    end

    def move_stockit_item_set
      @item.move_set_to_location(params["location_id"])
      render json: @item, serializer: stockit_serializer
    end

    private

    def stockit_serializer
      Api::V1::StockitSetItemSerializer
    end

    def update_offer_state(offer)
      offer.items.reload
      if [:reviewed, :scheduled].include?(offer.state_name) && offer.items.all?{|i| i.state_name == :rejected}
        offer.re_review!
      end
    end

    def item_params
      params.require(:item).permit(:donor_description, :donor_condition_id,
        :state_event, :offer_id, :package_type_id, :rejection_reason_id,
        :reject_reason, :rejection_comments)
    end

    def serializer
      Api::V1::ItemSerializer
    end

    def single_item_error
      render json:
        { errors: 'Cannot delete the last item of a submitted offer'}.to_json,
        status: 422
    end

    def rejecting_last_item_having_confirmed_ggv(offer)
      item_params[:state_event] == 'reject' &&
      offer.items.all?{|i| i.state_name == :rejected || i.id == @item.id} &&
      offer.gogovan_order && offer.scheduled? && !offer.can_cancel?
    end

    def render_require_ggv_cancel_error
      render json: { errors: [{ requires_gogovan_cancellation:
        'Cannot reject last item if there\'s a confirmed gogovan booking' }]
        }.to_json, status: 422
    end
  end
end
