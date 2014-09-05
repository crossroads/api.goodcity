module Api::V1
  class OffersController < Api::V1::ApiController

    before_filter :eager_load_offer, except: [:index, :create]
    load_and_authorize_resource :offer, parent: false

    def create
      @offer = Offer.new(offer_params)
      @offer.created_by = current_user
      if @offer.save
        render json: @offer, serializer: serializer, status: 201
      else
        render json: @offer.errors.to_json, status: 500
      end
    end

    # /offers?ids=1,2,3,4
    def index
      @offers = @offers.with_eager_load # this maintains security
      @offers = @offers.find(params[:ids].split(",")) if params[:ids].present?
      @offers = @offers.submitted if params[:state] == 'submitted'
      render json: @offers, each_serializer: serializer
    end

    def show
      render json: @offer, serializer: serializer
    end

    def update
      @offer.update_attributes(offer_params)
      @offer.update_saleable_items if params[:offer][:saleable]
      render json: @offer, serializer: serializer
    end

    def destroy
      @offer.draft? ? @offer.really_destroy! : @offer.destroy
      render json: {}
    end

    private

    def eager_load_offer
      @offer = Offer.with_eager_load.find(params[:id])
    end

    def offer_params
      params.require(:offer).permit(:language, :collection_contact_name,
        :state, :origin, :stairs, :parking, :estimated_size, :notes,
        :created_by_id, :collection_contact_phone)
    end

    def serializer
      Api::V1::OfferSerializer
    end

  end
end
