require 'rails_helper'

RSpec.describe Api::V1::CountriesController, type: :controller do

  let!(:user) { create(:user_with_token) }

  describe "POST fetch_packages" do
    before { generate_and_set_token(user) }
    it "response status 200" do
      post :create, country: {name_en: "China"}
      # expect {
      #   post :create, country: {name_en: "China"}
      # }.to change(Country, :count).by(1)
      expect(response.status).to eq(200)
    end
  end
end
