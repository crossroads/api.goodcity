require 'rails_helper'

RSpec.describe Api::V1::CountriesController, type: :controller do
  let(:user) { create(:user, :api_write) }
  let(:country_params_with_stockit_id) {
    FactoryBot.attributes_for(:country, :with_stockit_id)
  }
  let(:country_params) {
    FactoryBot.attributes_for(:country)
  }
  let(:parsed_body) {JSON.parse(response.body)}

  describe "POST countries" do
    before { generate_and_set_token(user) }

    context 'if stockit_id present in params' do
      it 'builds new record if record with stockit id do not exists in db' do
        expect{
          post :create, format: :json, country: country_params_with_stockit_id
        }.to change(Country, :count).by(1)
        expect(response.status).to eq(201)
      end

      it 'assigns values to existing record having stockit_id same as stockit_id in params' do
        country =  create :country, country_params_with_stockit_id
        expect{
          post :create, format: :json, country: country_params_with_stockit_id
        }.to change(Country, :count).by(0)
        expect(response.status).to eq(201)
      end
    end

    context 'stockit_id is not present in params' do
      it "creates new record" do
        expect{
          post :create, format: :json, country: country_params
        }.to change(Country, :count).by(1)
        expect(response.status).to eq(201)
      end
    end

    context "GET countries" do
      before do
        create(:country, name_en: "India")
        create(:country, name_en: "Indonesia")
        create(:country, name_en: "Hongkong")
        create(:country, name_en: "China")
        create(:country, name_en: "Australia")
      end

      describe "index country" do
        it "filters out coutries" do
          get :index, searchText: "Ind"
          expect(parsed_body["countries"].length).to eq(2)
        end

        it "return null if nothing matches" do
          get :index, searchText: "Fra"
          expect(parsed_body["countries"].length).to eq(0)
        end
      end
    end
  end

  describe '/show SHOW country' do
    let(:country) { create :country }
    before { generate_and_set_token(user) }

    it 'returns success status' do
      get :show, id: country.id
      expect(response).to have_http_status(:success)
    end

    it 'returns the country' do
      get :show, id: country.id
      expect(parsed_body['country']['id']).to eq(country.id)
      expect(parsed_body['country']['name_en']).to eq(country.name_en)
    end
  end
end
