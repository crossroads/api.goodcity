require 'rails_helper'

RSpec.describe Api::V1::OfferResponsesController, type: :controller do
  let(:authorized_user) { create(:user,:with_token) }
  let(:unauthorized_user) { create(:user) }
  let(:offer) { create(:offer) }
  let(:offer_response) { create(:offer_response)}
  let(:parsed_body) { JSON.parse(response.body) }

  describe 'POST v1/offer_responses' do
    context 'for unauthorized user' do
      it 'cannot create offer_response' do
        expect {
          post :create, params: { offer_response: {user_id: unauthorized_user.id,offer_id: offer.id} }
        }.to_not change { OfferResponse.count }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'for authorized user' do
      before { generate_and_set_token(authorized_user) }
      it 'creates new offer_response' do
        expect {
          post :create, params: { offer_response: {user_id: authorized_user.id,offer_id: offer.id} }
        }.to change(OfferResponse, :count).by(1)
        expect(response).to have_http_status(:success)
      end

      context 'when offer id is not present' do
        it 'does not create new offer_response' do
          expect {
            post :create, params: { offer_response: {user_id:authorized_user.id} }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'when user id is not present' do
        it 'does not create new offer_response' do
          expect {
            post :create, params: { offer_response: {offer_id:offer.id} }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end

  describe 'GET v1/offer_responses' do
    context 'for unauthorized user' do
      it 'cannot get offer_response' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'for authorized user' do
      before do
        generate_and_set_token(authorized_user)
        create_list(:offer_response, 1)
      end

      it 'does not returns offer response if no params is provided' do
        get :index
        expect(response.body).to eq("null")
      end

      context "does returns offer response if params provided " do

        before do
          create(:offer_response, user_id: authorized_user.id , offer_id: offer.id)
          create(:offer_response, user_id: authorized_user.id , offer_id: offer.id)
        end

        it 'is user and offer id' do
          get :index, params: {user_id:authorized_user.id,offer_id: offer.id}
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end

        it "is offer id" do
          get :index, params: {offer_id: offer.id}
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end

        it "is user id" do
          get :index, params: {user_id:authorized_user.id,}
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
