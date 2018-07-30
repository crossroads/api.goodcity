require 'rails_helper'

RSpec.describe Api::V1::LocationsController, type: :controller do

  let(:reviewer) { create(:user_with_token, :with_can_manage_locations_permission, role_name: 'Reviewer') }
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
      loc1 = create :location, building: "TestBuilding"
      create :location
      get :index, searchText: "TestBuilding"
      expect(parsed_body['locations'][0]['building']).to eql("TestBuilding")
      expect(parsed_body['meta']['total_pages']).to eql(1)
    end
    
  end

  describe "POST location/1" do
    it "create new location if stockit_id is not present", :show_in_doc do
      expect {
        post :create, location: {building: "234", area: "C"}
      }.to change(Location, :count).by(1)
      expect(response.status).to eq(201)
    end

    it "updates location if stockit_id is already present", :show_in_doc do
      location = create :location, stockit_id: 123
      expect {
        post :create, location: location.attributes
      }.to_not change(Location, :count)
      expect(response.status).to eq(201)
    end
  end

end
