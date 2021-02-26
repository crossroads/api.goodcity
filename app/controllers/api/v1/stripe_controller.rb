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

        # PARAMS:
        # {
        #   "stripe_response": {
        #     "id": "seti_1IOyT3JG1rVU4bz1mBbHH6Yu",
        #     "object": "setup_intent",
        #     "cancellation_reason": "",
        #     "client_secret": "seti_1IOyT3JG1rVU4bz1mBbHH6Yu_secret_J10Uje2R9PSUp74wN3S3TfwaDyCMMG8",
        #     "created": "1614315741",
        #     "description": "",
        #     "last_setup_error": "",
        #     "livemode": "false",
        #     "next_action": "",
        #     "payment_method": "pm_1IOyTrJG1rVU4bz1wYJv9s5N", "payment_method_types": ["card"],
        #     "status": "succeeded",
        #     "usage": "off_session"
        #   },
        #   "source_id": "1",
        #   "source_type": "transport_order",
        #   "authorize_amount": "true",
        #   "format": "json",
        #   "controller": "api/v1/stripe",
        #   "action": "save_payment_method"
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
