require 'rails_helper'

RSpec.describe Api::V1::BrowseController, type: :controller do

  let(:user) { create(:user_with_token) }

  describe "GET fetch_packages" do
    before { generate_and_set_token(user) }
    it "response status 200" do
      get :fetch_packages
      expect(response.status).to eq(200)
    end
  end
end