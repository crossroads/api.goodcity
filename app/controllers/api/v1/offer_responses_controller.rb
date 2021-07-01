module Api
  module V1
    class OfferResponsesController < Api::V1::ApiController
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

      api :POST, "/v1/offer_responses", "Create a Offer Response"
      def create
        record = OfferResponse.find_or_create_by(offer_responses_params)

        if record.save
          render json: record, serializer: serializer, status: 201
        else
          render json: { errors: record.errors.full_messages }, status: 422
        end
      end

      api :GET, "/v1/offer_responses"
      def index
        @offer_responses = @offer_responses.where(user_id: offer_responses_params["user_id"]) if offer_responses_params["user_id"].present?
        @offer_responses = @offer_responses.where(offer_id: offer_responses_params["offer_id"]) if offer_responses_params["offer_id"].present?
        render json: @offer_responses, each_serializer: serializer
      end

      private

      def offer_responses_params
        params.require(:offer_response).permit(:user_id, :offer_id)
      end

      def serializer
        Api::V1::OfferResponseSerializer
      end
    end
  end
end
