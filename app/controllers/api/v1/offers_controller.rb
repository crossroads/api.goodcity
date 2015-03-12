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
    param :ids, Array, of: Integer, desc: "Filter by offer ids e.g. ids = [1,2,3,4]"
    param :state, Offer.valid_states, desc: "Filter by an offer state e.g. state=draft"
    param :reviewed_by_id, String, desc: "Filter by reviewer id e.g. reviewed_by_id = 1"
    param :category, ["finished"], desc: "To get finished(received and closed) offers"
    def index
      return finished if params["category"] == "finished"
      @offers = params['state'] ?
        @offers.by_state(params['state']).with_eager_load :
        @offers.active.with_eager_load # this maintains security
      @offers = @offers.find(params[:ids].split(",")) if params[:ids].present?
      @offers = @offers.review_by(params['reviewed_by_id']) if params['reviewed_by_id']
      render json: @offers, each_serializer: serializer, exclude_messages: params[:exclude] == "messages"
    end

    def finished
      @offers = if params["reviewer"]
        Offer.inactive.review_by(User.current_user).with_eager_load
      else
        Offer.inactive.with_eager_load
      end
      render json: @offers, each_serializer: serializer, exclude_messages: params[:exclude] == "messages"
    end

    api :GET, '/v1/offers/1', "List an offer"
    def show
      render json: @offer, serializer: serializer, exclude_messages: params[:exclude] == "messages"
    end

    api :PUT, '/v1/offers/1', "Update an offer"
    param_group :offer
    param :saleable, [true, false], desc: "Can these items be sold?"
    def update
      @offer.update_attributes(offer_params)
      @offer.update_saleable_items if params[:offer][:saleable]
      render json: @offer, serializer: serializer
    end

    api :DELETE, '/v1/offers/1', "Delete an offer"
    description "If an offer is in draft state it will be destroyed. Any other state and it will be marked as deleted but remain recoverable."
    def destroy
      @offer.draft? ? @offer.really_destroy! : @offer.destroy
      render json: {}
    end

    api :PUT, '/v1/offers/1/review', "Assign current_user as Offer reviewer. If two or more reviewers start review at the same time, assign offer to the first reviewer and return offer with reviewer details to other reviewer(s)"
    def review
      begin
        Offer.transaction do
          @offer.lock!
          raise unless @offer.submitted?
          @offer.assign_reviewer(current_user)
          render json: @offer, serializer: serializer
        end
      rescue
        render json: @offer, serializer: serializer
      end
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
      @offer.update_attributes({ state_event: 'close' })
      render json: @offer, serializer: serializer
    end

    private

    def eager_load_offer
      @offer = Offer.with_eager_load.find(params[:id])
    end

    def offer_params
      attributes = [:language, :origin, :stairs, :parking, :estimated_size, :notes, :state_event]
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
