module Api::V1
  class BraintreeController < Api::V1::ApiController

    before_action :authorize_user, :braintree_object

    api :GET, '/v1/braintree/generate_token', "Get braintree token"
    def generate_token
      token = @braintree.client_token
      render json: { braintree_token: token }.to_json
    end

    api :POST, '/v1/braintree/make_transaction', "Get braintree token"
    param :amount, String, desc: "The donation amount donor wants to donate."
    param :payment_method_nonce, String, desc: "The token(nonce) returned by braintree server."
    def make_transaction
      response = @braintree.create_transaction(params["amount"], params["payment_method_nonce"])
      render json: { response: response }.to_json
    end

    private

    def authorize_user
      authorize!(:current_user_profile, User)
    end

    def braintree_object
      @braintree = BraintreeService.new(User.current_user)
    end

  end
end
