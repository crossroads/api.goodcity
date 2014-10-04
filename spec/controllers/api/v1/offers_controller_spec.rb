require 'rails_helper'

RSpec.describe Api::V1::OffersController, :type => :controller do

  let!(:user) { create(:user_with_specifics) }
  let(:offer) { create(:offer, created_by: user) }
  let(:serialized_offer) { Api::V1::OfferSerializer.new(offer) }
  let(:serialized_offer_json) { JSON.parse( serialized_offer.to_json ) }

  before { generate_and_set_token(user) }

  describe "GET offer" do
    before {  }
    it "returns 200" do
      get :show, id: offer.id
      expect(response.status).to eq(200)
    end
    it "return serialized offer", :show_in_doc do
      get :show, id: offer.id
      body = JSON.parse(response.body)
      expect( body ).to eq(serialized_offer_json)
    end
  end

end
