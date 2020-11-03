require 'rails_helper'

RSpec.describe Api::V1::LocationsController, type: :controller do
  let(:reviewer) { create(:user, :with_token, :with_can_manage_locations_permission, role_name: 'Reviewer') }
  let(:parsed_body) { JSON.parse(response.body) }
  before { generate_and_set_token(reviewer) }

  describe "GET locations" do
    let(:locations) { create_list(:location, 2) }

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized locations", :show_in_doc do
      create_list(:location, 2)
      get :index
      expect( parsed_body['locations'].length ).to eq(Location.count)
    end

    it "finds location using searchText" do
      create :location, building: "TestBuilding"
      create :location
      get :index, params: { searchText: "TestBuilding" }
      expect(parsed_body['locations'][0]['building']).to eql("TestBuilding")
      expect(parsed_body['meta']['total_pages']).to eql(1)
    end
  end

  describe "POST location/1" do
    it "create new location", :show_in_doc do
      expect {
        post :create, params: { location: {building: "234", area: "C" } }
      }.to change(Location, :count).by(1)
      expect(response.status).to eq(201)
    end
  end
end
