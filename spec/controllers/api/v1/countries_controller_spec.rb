require 'rails_helper'

RSpec.describe Api::V1::CountriesController, type: :controller do
  let(:user) { create(:user, :api_user) }
  let(:country_params) {
    FactoryGirl.attributes_for(:country)
  }

  describe "POST countries" do
    before { generate_and_set_token(user) }
    it 'create countries' do
      post :create, format: :json, country: country_params
      expect(response.status).to eq(201)
    end
  end
end
