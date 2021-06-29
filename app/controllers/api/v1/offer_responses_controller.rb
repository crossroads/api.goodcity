module Api
  module V1
    class  OfferResponsesController < Api::V1::ApiController
      authorize_resource :offer_response, parent: false
      load_resource :offer_response, only: [:index]

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :offer_response do
        param :offer_response, Hash, required: true do
          param :user_id, String, desc: "Id of user"
          param :offer_id, String, desc: "Id of offer"
        end
      end

      api :POST, "/v1/offer_responses","Create a offer Response"
      def create
        user_id, offer_id = params["offer_response"].values_at('user_id', 'offer_id')
        return  render json: { errors: "Offer and User Id required"}, status: 422 unless user_id.present? && offer_id.present?

        @offer_response=OfferResponse.new
        @offer_response.user=User.find_by_id(user_id)
        @offer_response.offer=Offer.find_by_id(offer_id)

        if @offer_response.save
          render json: @offer_response, serializer: serializer,status: 201
        else
          render json: { errors: @order.errors.full_messages }, status: 422
        end
      end

      api :GET, "/v1/offer_responses"
      def index
        user_id, offer_id = params.values_at('user_id', 'offer_id')
        record = get_offer_response(@offer_responses,user_id,offer_id)
        render json: record, each_serializer: serializer
      end

      private

      def offer_responses_params
        params.require(:offer_response).permit(:user_id, :offer_id)
      end

      def get_offer_response(records,user,offer)
        return  records.where(user_id: user,offer_id: offer) if user.present? && offer.present?
        return  records.where(user_id: user) if user.present?
        return  records.where(offer_id: offer) if offer.present?
      end

      def serializer
        Api::V1::OfferResponseSerializer
      end
    end
  end
end
