# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::CannedResponsesController, type: :controller do
  let(:user) { create(:user, :with_token, :with_supervisor_role, :with_can_manage_canned_response_permission) }
  let!(:canned_response) { create(:canned_response) }

  before(:each) { generate_and_set_token(user) }

  before do
    create_list(:canned_response, 5)
    create_list(:canned_response, 3, :system)
  end

  describe 'GET /index' do
    context 'valid user' do
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end
    end

    context 'invalid user' do
      let(:user) { create(:user, :with_token) }

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when message_type has invalid params' do
      it 'returns user canned_responses' do
        get :index, params: { message_type: 'qwerty' }
        res = response_json['canned_responses'].map { |c| c['message_type'] }
        expect(res.uniq).to match_array([CannedResponse::Type::USER])
      end
    end

    context 'when there is search parameter' do
      before do
        create(:canned_response, name_en: 'What are your opening hours?', content_en: 'We are open from 10AM to 10PM')
        create(:canned_response, name_en: 'How should I get to the office?', content_en: 'Get a cab!!')
        create(:canned_response, name_en: 'I need to donate items', content_en: 'Go ahead and submit with a good picture.')
      end

      it 'returns results based on the search parameter' do
        get :index, params: { searchText: 'opening hours' }
        expect(response_json['canned_responses'].length).to eq(1)
      end

      context 'when search parameter is empty' do
        it 'returns all user canned_responses' do
          get :index, params: { searchText: '' }
          expect(response_json['canned_responses'].length).to eq(CannedResponse.by_type(CannedResponse::Type::USER).count)
        end
      end

      context 'when search parameter does not match with anything' do
        it 'returns empty' do
          get :index, params: { searchText: 'item location' }
          expect(response_json['canned_responses']).to be_empty
        end
      end
    end

    context 'when message_type is system' do
      it 'returns system canned_responses in response' do
        get :index, params: { message_type: 'system' }
        expect(response_json['canned_responses'].length).to eq(3)
      end

      it 'response has system canned_responses only' do
        get :index, params: { message_type: 'SYSTEM' }
        res = response_json['canned_responses'].map { |c| c['message_type'] }
        expect(res.uniq).to match_array([CannedResponse::Type::SYSTEM])
      end

      context 'when search parameter is present' do
        before do
          create(:canned_response, :system, name_en: 'What are your opening hours?', content_en: 'We are open from 10AM to 10PM')
          create(:canned_response, :system, name_en: 'How should I get to the office?', content_en: 'Get a cab!!')
          create(:canned_response, :system, name_en: 'I need to donate items', content_en: 'Go ahead and submit with a good picture.')
        end

        it 'returns canned_responses based on the search parameter' do
          get :index, params: { searchText: 'opening hours', message_type: 'system' }
          expect(response_json['canned_responses'].length).to eq(1)
        end

        it 'response has system canned_responses only' do
          get :index, params: { searchText: 'opening hours', message_type: 'system' }
          res = response_json['canned_responses'].map { |c| c['message_type'] }
          expect(res.uniq).to match_array([CannedResponse::Type::SYSTEM])
        end
      end
    end

    context 'when message_type params is not present' do
      it 'returns user canned_responses in response' do
        get :index
        expect(response_json['canned_responses'].length).to eq(6)
      end

      it 'response do not have system canned_responses' do
        get :index, params: { message_type: 'user' }
        res = response_json['canned_responses'].map { |c| c['message_type'] }
        expect(res.uniq).to match_array([CannedResponse::Type::USER])
      end
    end
  end

  describe 'POST canned_response' do
    let(:canned_response_params) { FactoryBot.attributes_for(:canned_response) }
    before { generate_and_set_token(user) }

    context 'for unauthorized user' do
      it 'cannot create canned_responses' do
        user = create(:user, :with_token)
        generate_and_set_token(user)
        expect {
          post :create, params: { canned_response: canned_response_params }
        }.to_not change { CannedResponse.count }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'creates new canned_response' do
      expect {
        post :create, params: { canned_response: canned_response_params }
      }.to change(CannedResponse, :count).by(1)
      expect(response).to have_http_status(:success)
    end

    context 'when name_en is not present' do
      it 'does not create new canned_response' do
        canned_response_params[:name_en] = nil
        expect {
          post :create, params: { canned_response: canned_response_params }
        }.to_not change { CannedResponse.count }

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when content_en is not present' do
      it 'does not create new canned_response' do
        canned_response_params[:content_en] = nil
        expect {
          post :create, params: { canned_response: canned_response_params }
        }.to_not change { CannedResponse.count }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when name_zh_tw is not present' do
      it 'creates new canned_response' do
        canned_response_params[:name_zh_tw] = nil
        expect {
          post :create, params: { canned_response: canned_response_params }
        }.to change { CannedResponse.count }.by(1)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when content_zh_tw is not passed' do
      it 'creates new canned_response' do
        canned_response_params[:content_zh_tw] = nil
        expect {
          post :create, params: { canned_response: canned_response_params }
        }.to change { CannedResponse.count }.by(1)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "UPDATE canned_response" do
    before { generate_and_set_token(user) }

    context 'for unauthorized user' do
      it 'cannot update canned_messages' do
        user = create(:user, :with_token)
        generate_and_set_token(user)
        expect {
          put :update, params: { id: canned_response.id, canned_response: { name_en: 'abcd' } }
        }.to_not change { canned_response.reload }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'update existing canned_response' do
      name_en = 'When is the weeko off?'
      put :update, params: { id: canned_response.id, canned_response: { name_en: name_en } }
      expect(response).to have_http_status(:success)
      expect(canned_response.reload.name_en).to eq(name_en)
    end

    context 'when name_en is updated to empty' do
      it 'does not update canned_response' do
        expect {
          put :update, params: { id: canned_response.id, canned_response: { name_en: '' } }
        }.to_not change { canned_response.reload }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when content_en is updated to blank' do
      it 'does not update canned_response' do
        expect {
          put :update, params: { id: canned_response.id, canned_response: { content_en: '' } }
        }.to_not change { canned_response.reload }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'when content_en is updated to blank' do
      it 'updates name_zh_tw to blank' do
        put :update, params: { id: canned_response.id, canned_response: { name_zh_tw: '' } }
        expect(response).to have_http_status(:success)
        expect(canned_response.reload.name_zh_tw).to be_empty
      end
    end

    context 'when content_en is updated to blank' do
      it 'updates content_zh_tw to blank' do
        put :update, params: { id: canned_response.id, canned_response: { content_zh_tw: '' } }
        expect(response).to have_http_status(:success)
        expect(canned_response.reload.content_zh_tw).to be_empty
      end
    end
  end

  describe 'DELETE canned_response' do
    before { generate_and_set_token(user) }

    context 'for unauthorized user' do
      it 'cannot destroy canned_messages' do
        user = create(:user, :with_token)
        generate_and_set_token(user)
        expect {
          delete :destroy, params: { id: canned_response.id }
        }.to_not change { CannedResponse.count }
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'destroy canned_response' do
      expect {
        delete :destroy, params: { id: canned_response.id }
      }.to change { CannedResponse.count }.by(-1)
      expect(response).to have_http_status(:success)
    end

    context 'for system messages' do
      let(:canned_response) { create(:canned_response, :system) }
      it 'cannot delete messagees' do
        expect {
          delete :destroy, params: { id: canned_response.id }
        }.to_not change { CannedResponse.count }
      end
    end
  end

  describe 'GET canned_response' do
    it 'returns canned response identified by guid params' do
      get :show, params: { guid: canned_response.guid }
      expect(response_json['canned_response']['id']).to eq(canned_response.id)
    end

    context 'if guid params is invalid' do
      it 'throws error' do
        get :show, params: { guid: 'abc' }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when non admin user try to GET canned_response' do
      let(:user) { create(:user, :order_administrator) }

      it 'throws error' do
        get :show, params: { guid: 'abc' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
