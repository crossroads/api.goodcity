module Api
  module V1
    class OfferResponsesController < Api::V1::ApiController
      load_and_authorize_resource :offer_response, parent: false

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
        save_and_render_object_with_errors(@offer_response)
      end

      api :GET, "/v1/offer_responses"
      def index
        @offer_responses = @offer_responses.where(user_id: offer_response_params["user_id"]) if offer_response_params["user_id"].present?
        @offer_responses = @offer_responses.where(offer_id: offer_response_params["offer_id"]) if offer_response_params["offer_id"].present?
        render json: @offer_responses, each_serializer: serializer
      end

      api :GET, "/v1/offer_responses/1"
      def show
        render json: @offer_response, serializer: serializer
      end

      private

      def offer_response_params
        params.require(:offer_response).permit(:user_id, :offer_id)
      end

      def serializer
        Api::V1::OfferResponseSerializer
      end
    end
  end
end
