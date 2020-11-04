require 'rails_helper'

RSpec.describe Api::V1::CountriesController, type: :controller do
  let(:user) { create(:user, :api_write) }
  let(:country_params) {
    FactoryBot.attributes_for(:country)
  }
  let(:country_params) {
    FactoryBot.attributes_for(:country)
  }
  let(:parsed_body) {JSON.parse(response.body)}

  describe "POST countries" do
    before { generate_and_set_token(user) }

    it "creates new record" do
      expect{
        post :create, params: { country: country_params }
      }.to change(Country, :count).by(1)
      expect(response.status).to eq(201)
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
          get :index, params: { searchText: "Ind" }
          expect(parsed_body["countries"].length).to eq(2)
        end

        it "return null if nothing matches" do
          get :index, params: { searchText: "Fra" }
          expect(parsed_body["countries"].length).to eq(0)
        end
      end
    end
  end
end
