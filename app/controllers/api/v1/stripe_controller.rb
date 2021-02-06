module Api
  module V1
    class StripeController < Api::V1::ApiController

      # skip_before_action :validate_token, only: [:index, :show]
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
      def save_payment_method
        puts params
        render json: params
      end

    end
  end
end
