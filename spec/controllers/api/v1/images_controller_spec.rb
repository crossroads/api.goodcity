require 'rails_helper'

RSpec.describe Api::V1::ImagesController, type: :controller do
  let(:cloudinary_config) { Rails.application.secrets.cloudinary }
  let(:user) { create(:user, :with_token) }
  let(:offer) { create :offer, created_by: user }
  let(:item)  { create :item, offer: offer }
  let(:image) { create :image, favourite: true, item: item }

  subject { JSON.parse(response.body) }

  describe "GET generate_signature" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :generate_signature
      expect(response.status).to eq(200)
    end

    it "return cloudinary signature", :show_in_doc do
      get :generate_signature
      body = JSON.parse(response.body)
      expect(body['api_key']).to eq(cloudinary_config[:api_key])
      expect(body.keys).to eq(%w[api_key signature timestamp tags])
    end

    # don't want client apps displaying error if app is simply out of data and image
    # has already been deleted
    it "returns 200 for deleting missing image" do
      delete :destroy, params: { id: -1 }
      expect(response.status).to eq(200)
    end
  end
end
