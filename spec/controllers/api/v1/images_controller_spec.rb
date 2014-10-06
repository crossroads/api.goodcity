require 'rails_helper'

RSpec.describe Api::V1::ImagesController, type: :controller do

  let(:user) { create(:user_with_token) }

  describe "GET generate_cloudinary_signature" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :generate_cloudinary_signature
      expect(response.status).to eq(200)
    end

    it "return cloudinary signature", :show_in_doc do
      get :generate_cloudinary_signature
      body = JSON.parse(response.body)
      expect( body.keys ).to eq(["api_key", "callback", "signature", "timestamp"])
    end
  end
end
