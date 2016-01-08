require 'rails_helper'

RSpec.describe Api::V1::LocationsController, type: :controller do

  describe "GET locations" do
    let(:locations) { create_list(:location, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized locations", :show_in_doc do
      create_list(:location, 2)
      get :index
      body = JSON.parse(response.body)
      expect( body['locations'].length ).to eq(Location.count)
    end
  end

  describe "POST location/1" do
    it "create new location if stockit_id is not present", :show_in_doc do
      expect {
        post :create, location: (build :location).attributes
      }.to change(Location, :count).by(1)
      expect(response.status).to eq(201)
    end

    it "updates location if stockit_id is already present", :show_in_doc do
      location = create :location
      expect {
        post :create, location: location.attributes
      }.to_not change(Location, :count)
      expect(response.status).to eq(201)
    end
  end

end
