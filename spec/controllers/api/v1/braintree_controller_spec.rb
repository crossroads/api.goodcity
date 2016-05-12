require 'rails_helper'
require 'ffaker'

RSpec.describe Api::V1::BraintreeController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:token) { rand(100000..999999) }

  describe "GET braintree/generate_token" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      expect(Braintree::ClientToken).to receive(:generate).and_return(token)
      get :generate_token
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["braintree_token"]).to eq(token)
    end
  end

  describe "POST braintree/make_transaction" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      braintree_response = {}
      allow_any_instance_of(BraintreeService).to receive(:create_transaction).and_return(braintree_response)
      expect(braintree_response).to receive(:success?).and_return(true)
      post :make_transaction, amount: 200, payment_method_nonce: token
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)["response"]).to eq(true)
    end
  end

end
