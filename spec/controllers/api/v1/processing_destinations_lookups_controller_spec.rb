require 'rails_helper'

RSpec.describe Api::V1::ProcessingDestinationsLookupsController, type: :controller do
  let(:user) { create(:user, :with_token, :with_supervisor_role, :with_can_manage_packages_permission) }

  let(:invalid_user) { create(:user, :with_token) }

  before do
    create_list(:processing_destinations_lookup, 3)
    generate_and_set_token(user)
  end

  describe 'GET /index' do
    context 'for valid user' do
      it 'response to be success' do
        get :index
        expect(response).to have_http_status(:success)
      end

      it 'returns a list of processing_destination_lookup' do
        get :index
        response = response_json['processing_destinations_lookups']
        expect(response.length).to eq(3)
        expect(response.map { |i| i['name'] }).to match_array(ProcessingDestinationsLookup.pluck(:name))
      end
    end

    context 'for invalid user' do
      before { generate_and_set_token(invalid_user) }
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
