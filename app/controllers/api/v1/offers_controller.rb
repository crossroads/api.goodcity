require "goodcity/offer_utils"

module Api::V1
  class OffersController < Api::V1::ApiController

    before_action :eager_load_offer, except: [:index, :create, :finished]
    load_and_authorize_resource :offer, parent: false

    resource_description do
      short "List, create, update and delete offers."
      description <<-EOS
        Only offers that are visible to the current user are returned.
        Donors will only see their offers. Reviewers will see offers from
        all users.
        == Offer states
        [link:/doc/offer_state.png]
      EOS
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :offer do
      param :offer, Hash, required: true do
        param :language, I18n.available_locales.map(&:to_s), desc: "Offer language. If not set, defaults to API header language.", allow_nil: true
        param :state_event, Offer.valid_events, desc: "Fires the state transition (if allowed) for this offer.", allow_nil: true
        param :origin, String, desc: "Not yet used", allow_nil: true
        param :stairs, [true, false], desc: "Does offer collection involve using stairs?", allow_nil: true
        param :parking, [true, false], desc: "Is parking provided?", allow_nil: true
        param :estimated_size, String, desc: "How big is the item?", allow_nil: true
        param :notes, String, desc: "Not yet used", allow_nil: true
        param :reviewed_by_id, String, allow_nil: true, desc: "User id of reviewer who is looking at the offer. Can only be set by reviewers. It will be ignored otherwise."
        param :delivered_by, String, allow_nil: true, desc: "The method used to deliver the offer to Crossroads, to be populated when closing an offer"
      end
    end

    api :POST, '/v1/offers', "Create an offer"
    param_group :offer
    def create
      @offer = Offer.new(offer_params)
      @offer.created_by = current_user
      if @offer.save
        render json: @offer, serializer: serializer, status: 201
      else
        render json: @offer.errors.to_json, status: 422
      end
    end

    api :GET, '/v1/offers', "List all offers"
    param :states, Array, in: Offer.valid_states + ["active", "not_active", "nondraft", "for_donor"], desc: "Filter by offer states. Note: you can also use the pseudo states 'not_active' or 'nondraft' which mean states=['#{Offer.not_active_states.join('\', \'')}'] and states=['#{Offer.nondraft_states.join('\', \'')}'] respectively."
    param :created_by_id, String, desc: "Return offers created by the given user id."
    param :reviewed_by_id, String, desc: "Return offers reviewed by the given user id."
    param :exclude_messages, ["true", "false"], desc: "If true, API response will not include messages."
    def index
      states = params["states"]
      @offers = @offers.in_states(states) if states.present?
      @offers = @offers.created_by(params["created_by_id"]) if params["created_by_id"].present?
      @offers = @offers.reviewed_by(params["reviewed_by_id"]) if params["reviewed_by_id"].present?
      render json: @offers.with_eager_load, each_serializer: serializer, exclude_messages: params["exclude_messages"] == "true"
    end

    api :GET, '/v1/offers/1', "List an offer"
    def show
      render json: @offer, serializer: serializer, exclude_messages: params["exclude_messages"] == "true"
    end

    api :PUT, '/v1/offers/1', "Update an offer"
    param_group :offer
    param :saleable, [true, false], desc: "Can these items be sold?"
    def update
      @offer.update_saleable_items if params[:offer][:saleable]
      @offer.update_attributes(offer_params)
      render json: @offer, serializer: serializer
    end

    api :DELETE, '/v1/offers/1', "Delete an offer"
    description "If an offer is in draft state it will be destroyed. Any other state will be changed to 'cancelled'."
    def destroy
      (@offer.draft? || current_user.staff?) ? @offer.really_destroy! :
        @offer.cancel
      render json: {}
    end

    api :PUT, '/v1/offers/1/review', "Assign current_user as Offer reviewer. If two or more reviewers start review at the same time, assign offer to the first reviewer and return offer with reviewer details to other reviewer(s)"
    def review
      @offer.with_lock do
        @offer.assign_reviewer(current_user) if @offer.submitted?
      end
      render json: @offer, serializer: serializer
    end

    api :PUT, '/v1/offers/1/complete_review', "Mark review as completed"
    param :offer, Hash, required: true do
      param :state_event, String, "State transition event ex: 'finish_review'"
      param :gogovan_transport_id, String, allow_nil: true
      param :crossroads_transport_id, String, allow_nil: true
    end
    def complete_review
      @offer.update_attributes(review_offer_params)
      render json: @offer, serializer: serializer
    end

    api :PUT, '/v1/offers/1/close_offer', "Mark Offer as closed."
    def close_offer
      @offer.update_attributes({ state_event: 'mark_unwanted' })
      @offer.send_message(params["close_offer_message"], User.current_user)
      render json: @offer, serializer: serializer
    end

    api :PUT, '/v1/offers/1/receive_offer', "Mark Offer as received."
    def receive_offer
      @offer.update_attributes({ state_event: 'receive' })
      @offer.send_message(params["close_offer_message"], User.current_user)
      render json: @offer, serializer: serializer
    end

    api :PUT, '/v1/offers/1/mark_inactive', "Mark offer as inactive"
    def mark_inactive
      @offer.update_attributes({ state_event: 'mark_inactive' })
      @offer.send_message(params["offer"]["inactive_message"], User.current_user)
      render json: @offer, serializer: serializer
    end

    def merge_offer
      status = Goodcity::OfferUtils.merge_offer!(offer_id: params["base_offer_id"], other_offer_id: @offer.id)
      render json: { status: status }.to_json
    end

    private

    def eager_load_offer
      @offer = Offer.with_eager_load.find(params[:id])
    end

    def offer_params
      attributes = [:language, :origin, :stairs, :parking, :estimated_size,
        :notes, :delivered_by, :state_event, :cancel_reason,
        :cancellation_reason_id]
      params.require(:offer).permit(attributes)
    end

    def review_offer_params
      params[:offer][:state_event] = 'finish_review'
      attributes = [:gogovan_transport_id, :crossroads_transport_id,
        :state_event]
      params.require(:offer).permit(attributes)
    end

    def serializer
      Api::V1::OfferSerializer
    end
  end
end
