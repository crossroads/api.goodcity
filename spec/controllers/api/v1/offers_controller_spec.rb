require 'rails_helper'

RSpec.describe Api::V1::OffersController, :type => :controller do

  let(:user) { create(:user_with_token) }
  let(:reviewer) { create(:user, :reviewer) }
  let(:offer) { create(:offer, created_by: user) }
  let(:serialized_offer) { Api::V1::OfferSerializer.new(offer) }
  let(:serialized_offer_json) { JSON.parse( serialized_offer.to_json ) }
  let(:allowed_params) { [:language, :origin, :stairs, :parking, :estimated_size, :notes] }
  let(:offer_params) { FactoryGirl.attributes_for(:offer).tap{|attrs| (attrs.keys - allowed_params).each{|a| attrs.delete(a)} } }

  describe "GET offers" do
    before { generate_and_set_token(reviewer) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end
    it "return serialized offers", :show_in_doc do
      2.times{ create :offer }
      get :index
      body = JSON.parse(response.body)
      expect( body['offers'].length ).to eq(2)
    end
  end

  describe "GET offer/1" do
    before { generate_and_set_token(user) }
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

  describe "POST offer/1" do
    before { generate_and_set_token(user) }
    it "returns 201", :show_in_doc do
      post :create, offer: offer_params
      expect(response.status).to eq(201)
    end
  end

  describe "PUT offer/1" do
    context "owner" do
      before { generate_and_set_token(user) }
      it "owner can submit", :show_in_doc do
        extra_params = { state_event: 'submit', saleable: true}
        expect(offer).to be_draft
        put :update, id: offer.id, offer: offer_params.merge(extra_params)
        expect(response.status).to eq(200)
        expect(offer.reload).to be_submitted
      end
    end
  end

  describe "DELETE offer/1" do
    before { generate_and_set_token(user) }
    it "returns 200", :show_in_doc do
      delete :destroy, id: offer.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end

end
