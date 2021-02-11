# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::CannedResponsesController, type: :controller do
  let(:user) { create(:user, :with_token, :with_supervisor_role, :with_can_manage_canned_response_permission) }
  let(:parsed_body) { JSON.parse(response.body) }

  before(:each) { generate_and_set_token(user) }
  before do
    create_list(:canned_response, 5)
  end

  describe 'GET /index' do
    context 'valid user' do
      it 'returns success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns all canned_responses' do
        get :index
        expect(parsed_body['canned_responses'].length).to eq(5)
        expect(parsed_body['canned_responses'].map { |res| res['id'] }).to eq(CannedResponse.pluck(:id))
      end
    end

    context 'invalid user' do
      let(:user) { create(:user, :with_token) }

      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:forbidden)
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
        expect(parsed_body['canned_responses'].length).to eq(1)
      end

      context 'when search parameter is empty' do
        it 'returns all canned_responses' do
          get :index, params: { searchText: '' }
          expect(parsed_body['canned_responses'].length).to eq(CannedResponse.count)
        end
      end

      context 'when search parameter does not match with anything' do
        it 'returns empty' do
          get :index, params: { searchText: 'item location' }
          expect(parsed_body['canned_responses']).to be_empty
        end
      end
    end
  end

  describe "POST canned_response" do
    before { generate_and_set_token(user) }

    it "creates new canned_response" do
      expect{
        post :create, params: { canned_response: { name_en: 'What are your opening hours?', content_en: 'We are open from 10AM to 10PM' } }
      }.to change(CannedResponse, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

  describe "UPDATE canned_response" do
    before {generate_and_set_token(user)}

    it "update existing canned_response" do
      canned_response = create(:canned_response, name_en: 'What are your opening hours?', content_en: 'We are open from 10AM to 10PM')
      put :update, params: { id: canned_response.id, canned_response: { name_en: "When is the weeko off?" } }
      expect(response.status).to eq(200)
    end
  end

  describe "DELETE canned_response" do
    before {generate_and_set_token(user)}

    it "destroy canned_response" do
      canned_response = create(:canned_response, name_en: 'What are your opening hours?', content_en: 'We are open from 10AM to 10PM')
      delete :destroy, params:{ id: canned_response.id }
      expect(response.status).to eq(200)
    end
  end
end
