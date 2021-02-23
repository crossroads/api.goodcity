module Api
  module V1
    class StripeController < Api::V1::ApiController

      load_and_authorize_resource class: false

      api :GET, "/v1/fetch_public_key", "Get stripe public key"
      def fetch_public_key
        render json: StripeService.new.public_key
      end

      api :POST, "/v1/create_setupintent", "Create setup-intent for current-user"
      def create_setupintent
        render json: StripeService.new.create_setup_intent
      end

      api :POST, "/v1/save_payment_method", "Save payment-method"
      param :stripe_response, Hash, required: true
      param :source_id, [Integer, String], required: true, desc: "Id of the source (transport_order)"
      param :source_type, String, required: true, desc: "Type of the source (transport_order)"
      param :authorize_amount, [true, false, 'true', 'false'], allow_nil: true, default: false, desc: 'Amount should be authorized from card for given source'
      def save_payment_method
        # stripe_response = {
        #   "id"=>"seti_1ILLMvJG1rVU4bz1HIM6tijG",
        #   "object"=>"setup_intent",
        #   "cancellation_reason"=>"",
        #   "client_secret"=>
        #     "seti_1ILLMvJG1rVU4bz1HIM6tijG_secret_IxFs70kJjXmCk2UaIm8DqvB5C3iHod0",
        #   "created"=>"1613450461",
        #   "description"=>"",
        #   "last_setup_error"=>"",
        #   "livemode"=>"false",
        #   "next_action"=>"",
        #   "payment_method"=>"pm_1ILLjYJG1rVU4bz1ElxLd5Mj", # <----
        #   "payment_method_types"=>["card"],
        #   "status"=>"succeeded",
        #   "usage"=>"off_session"
        # }

        StripeService.new(
          source_type: params[:source_type],
          source_id: params[:source_id],
          authorize_amount: params[:authorize_amount]
        ).save_payment_method(params[:stripe_response])

        render json: params
      end

    end
  end
end
