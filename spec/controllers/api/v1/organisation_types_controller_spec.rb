# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::V1::OrganisationTypesController, type: :controller do
  let(:user) { create(:user, :with_order_administrator_role, :with_can_access_organisation_types_permission) }
  let(:response_body) { JSON.parse(response.body) }
  let!(:organisation_types) { create_list(:organisation_type, 3) }

  before do
    generate_and_set_token(user)
  end

  describe 'GET index' do
    it 'returns 200' do
      get :index
      expect(response).to have_http_status(:success)
    end

    context 'for invalid user' do
      let(:user) { create(:user) }
      it 'returns unauthorized' do
        get :index
        expect(response).to have_http_status(:forbidden)
      end
    end

    it 'returns the organisation_types' do
      get :index
      expect(response_body['organisation_types'].length).to eq(OrganisationType.count)
      # expect(response_body['organisation_types'].to include(organisation_types.map { |o| {"name" => o.name_en, "id" => o.id } } )
      expect(response_body['organisation_types']).to match_array(organisation_types.map{|o| { 'name' => o.name_en, 'id' => o.id, 'category' => o.category_en } })
    end
  end
end
