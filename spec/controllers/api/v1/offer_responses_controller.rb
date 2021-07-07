require 'rails_helper'

RSpec.describe Api::V1::OfferResponsesController, type: :controller do
  let(:authorized_user) { create(:user,:with_token) }
  let(:unauthorized_user) { create(:user) }
  let(:offer) { create(:offer) }
  let(:offer_response) { create(:offer_response) }
  let(:offer_response_params) { FactoryBot.attributes_for(:offer_response, user_id: authorized_user.id, offer_id: offer.id ) }
  let(:parsed_body) { JSON.parse(response.body) }

  describe 'POST v1/offer_responses' do
    context 'for unauthorized user' do
      it 'cannot create offer_response' do
        expect {
          post :create, params: { offer_response: { user_id: unauthorized_user.id,offer_id: offer.id } }
        }.to_not change { OfferResponse.count }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'for authorized user' do
      before { generate_and_set_token(authorized_user) }

      context 'when offer id and user id is present and offer is not shared' do
        it 'does not create new offer_response' do
          expect {
            post :create, params: { offer_response: offer_response_params }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when offer id and user id is present and offer is publicly shared' do
        before { Shareable.publish(offer) }
        it 'create new offer_response if params are correct' do
          expect {
            post :create, params: { offer_response: offer_response_params }
          }.to change(OfferResponse, :count).by(1)
          expect(response).to have_http_status(:success)
        end

        it 'does not create new offer_response if params are incorrect' do
          expect {
            post :create, params: { offer_response: { user_id: unauthorized_user.id, offer_id: offer.id
            } }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:forbidden)
        end

        context 'does not create duplicate offer_response' do
          before { create(:offer_response, user_id: authorized_user.id , offer_id: offer.id) }
          it 'if the record is already present' do
            expect {
              post :create, params: { offer_response: offer_response_params }
            }.to raise_error(ActiveRecord::RecordNotUnique)
          end
        end
      end

      context 'when offer id is not present' do
        it 'does not create new offer_response' do
          expect {
            post :create, params: { offer_response: { user_id:authorized_user.id } }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'when user id is not present' do
        it 'does not create new offer_response' do
          expect {
            post :create, params: { offer_response: { offer_id:offer.id } }
          }.to_not change { OfferResponse.count }
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end

  describe "GET v1/offer_responses/1" do

    let(:offer_response1) { create(:offer_response, user_id: authorized_user.id, offer_id: offer.id) }
    context 'for unauthorized user' do
      it 'cannot get offer_response' do
        get :index
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'for authorized user' do
      before do
        generate_and_set_token(authorized_user)
      end

      it 'returns offer response if offer response id is provided' do
        get :show, params: { id: offer_response1.id }
        expect(response).to have_http_status(:success)
        expect(parsed_body['offer_response']['id']).to eq(offer_response1.id)
      end

      it "does not return offer response of other user"do
        get :show, params: { id: offer_response.id }
        expect(response).to have_http_status(:forbidden)
      end

      it 'does not returns offer response if no offer response id is provided' do
        get :show, params: { id: ""}
        expect(parsed_body['offer_response']).to eq(nil)
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
        create(:user,:with_token)
      end

      context'does not returns offer response' do
        it 'if no params is provided' do
          offer_response_params['user_id']=""
          offer_response_params['offer_id']=""
          get :index, params: { offer_response: offer_response_params }
          expect(parsed_body['offer_responses']).to eq([])
        end

        it 'if user is trying to get other offer response' do
          offer_response_params['user_id']=authorized_user.id
          offer_response_params['offer_id']=""
          get :index, params: { offer_response: offer_response_params }
          expect(parsed_body['offer_responses']).to eq([])
        end
      end

      context "does returns offer response if params provided " do
        before do
          create(:offer_response, user_id: authorized_user.id , offer_id: offer.id)
        end

        it 'is valid user and valid offer id' do
          get :index, params: { offer_response: offer_response_params }
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end

        it "is valid offer id" do
          offer_response_params['user_id']=""
          get :index, params: { offer_response: offer_response_params }
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end

        it "is valid user id" do
          offer_response_params['offer_id']=""
          get :index, params: { offer_response: offer_response_params }
          expect(parsed_body['offer_responses'][0]['user_id']).to eq(authorized_user.id)
          expect(parsed_body['offer_responses'][0]['offer_id']).to eq(offer.id)
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
