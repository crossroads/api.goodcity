module Api::V1
  class OffersController < Api::V1::ApiController

    before_filter :load_offer, except: [:index]
    load_and_authorize_resource :offer, parent: false

    # /offers?ids=1,2,3,4
    def index
      @offers = Offer.with_eager_load
      if params[:ids].present?
        @offers = @offers.find( params[:ids].split(",") )
      end
      render json: @offers, each_serializer: serializer
    end

    def show
      render json: @offer, serializer: serializer
    end

    def update
      # TODO whitelisting
      @offer.update_attributes( params[:offer], :without_protection => true )
      render json: @offer, serializer: serializer
    end

    def destroy
      @offer.destroy
      render json: {}
    end

    private

    def serializer
      Api::V1::OfferSerializer
    end

    def load_offer
      @offer = Offer.with_eager_load.find( params[:id] )
    end

  end
end
