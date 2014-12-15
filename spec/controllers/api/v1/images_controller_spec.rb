require 'rails_helper'

RSpec.describe Api::V1::ImagesController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:offer) { create :offer, created_by: user }
  let(:item)  { create :item, offer: offer }
  let(:image) { create :image, favourite: true, item: item }

  subject { JSON.parse(response.body) }

  describe "GET images" do
    before { generate_and_set_token(user) }
    it "return serialized images", :show_in_doc do
      pending "error in postgres_ext-serializers but not currently used"
      2.times { create :image, item: item }
      get :index
      expect(response.status).to eq(200)
      expect(subject['images'].length ).to eq(2)
    end
  end

  describe "GET generate_signature" do
    before { generate_and_set_token(user) }

    it "returns 200" do
      get :generate_signature
      expect(response.status).to eq(200)
    end

    it "return cloudinary signature", :show_in_doc do
      get :generate_signature
      body = JSON.parse(response.body)
      expect( body.keys ).to eq(["api_key", "callback", "signature", "timestamp"])
    end

    # don't want client apps displaying error if app is simply out of data and image
    # has already been deleted
    it "returns 200 for deleting missing image" do
      delete :destroy, id: -1
      expect(response.status).to eq(200)
    end
  end
end
